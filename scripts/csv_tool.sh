# 共通の前置き（よく使うモジュールの import、パイプ途中で閉じられたときの BrokenPipeError 防止、CSV の書き出し用の w）を付けて python3 を実行する
# 使い方: _csv_py '<python のコード>' [引数...]
_csv_py() {
	python3 -c "import csv, sys, re, json, signal, itertools
signal.signal(signal.SIGPIPE, signal.SIG_DFL)
sys.stdin.reconfigure(encoding=\"utf-8-sig\")  # Excel で保存した CSV の先頭の BOM を取り除く
# 引数の間違いなどでトレースバックを出さない（Ctrl-C は何も出さずに終える）
sys.excepthook = lambda t, e, tb: sys.exit(130 if t is KeyboardInterrupt else f\"エラー: {t.__name__}: {e}\")
w = csv.writer(sys.stdout, lineterminator='\\n')
$1" "${@:2}"
}

# 標準入力から CSV を受け取り、ヘッダーを表示する
csv_head() {
	_csv_py '
r = csv.reader(sys.stdin)
for i, h in enumerate(next(r, [])):
    print(f"{i+1:02}: {h}")
'
}

# 標準入力から CSV を受け取り、列名を引数で指定して表示する
csv_cut() {
	_csv_py '
cols = sys.argv[1:]
if not cols:
    sys.exit("使い方: csv_cut 列名...")
r = csv.DictReader(sys.stdin)
missing = [c for c in cols if c not in (r.fieldnames or cols)]  # 入力が空なら調べない
if missing:
    sys.exit("列がありません: " + ", ".join(missing))

w.writerow(cols)
for row in r:
    w.writerow([row.get(c, "") for c in cols])
' "$@"
}

# 標準入力から CSV を受け取り、列番号を引数で指定して表示する
csv_cutn() {
	_csv_py '
if len(sys.argv) < 2:
    sys.exit("使い方: csv_cutn 列番号...")
cols = [int(c) - 1 for c in sys.argv[1:]]
if any(c < 0 for c in cols):
    sys.exit("列番号は 1 以上で指定してください")
r = csv.reader(sys.stdin)

for row in r:
    w.writerow([row[c] if c < len(row) else "" for c in cols])
' "$@"
}

# 標準入力から CSV を受け取り、指定した行数までを出力
csv_limit() {
	_csv_py '
limit = int(sys.argv[1]) if len(sys.argv) > 1 else 10
w.writerows(itertools.islice(csv.reader(sys.stdin), limit))
' "$@"
}

# 標準入力から CSV を受け取り、先頭N行をスキップして出力する
csv_skip() {
	_csv_py '
skip = int(sys.argv[1]) if len(sys.argv) > 1 else 1
w.writerows(itertools.islice(csv.reader(sys.stdin), skip, None))
' "$@"
}

# 標準入力から CSV を受け取り、指定したカラムに対して正規表現でフィルタする
#
# 【使い方】
#   csv_grep カラム名1 正規表現1 [カラム名2 正規表現2 ...]
#   複数指定すると OR 条件になる（AND 条件したい場合はパイプで繋げれば良い）
#
# 【例】
#   cat data.csv | csv_grep name "太郎"
#   cat data.csv | csv_grep name "太郎" city "大阪"
#   cat data.csv | csv_grep name "太郎" | csv_grep city "大阪"
#   cat data.csv | csv_grep name '^佐' city '東京|横浜'
csv_grep() {
	_csv_py '
args = sys.argv[1:]
if len(args) < 2 or len(args) % 2 != 0:
    sys.exit("使い方: csv_grep col1 regex1 [col2 regex2 ...]")

# カラム名と正規表現のペアをリスト化
pairs = [(args[i], re.compile(args[i+1])) for i in range(0, len(args), 2)]  # 出力の前に正規表現を確かめる

r = csv.DictReader(sys.stdin)

# 出力ヘッダ
if r.fieldnames is None:  # 入力が空
    sys.exit(0)
missing = [c for c, _ in pairs if c not in r.fieldnames]
if missing:
    sys.exit("列がありません: " + ", ".join(missing))
w.writerow(r.fieldnames)

for row in r:
    for col, pattern in pairs:
        if pattern.search(row[col] or ""):
            w.writerow([row[c] for c in r.fieldnames])
            break  # OR条件なのでマッチしたら次の行へ
' "$@"
}
# カラム名ではなく列番号
csv_grepn() {
	_csv_py '
args = sys.argv[1:]
if len(args) < 2 or len(args) % 2 != 0:
    sys.exit("使い方: csv_grepn colnum1 regex1 [colnum2 regex2 ...]")

# カラム番号と正規表現のペア（1始まり → 0始まりへ変換）
pairs = [(int(args[i]) - 1, re.compile(args[i+1])) for i in range(0, len(args), 2)]  # 出力の前に正規表現を確かめる
if any(c < 0 for c, _ in pairs):
    sys.exit("列番号は 1 以上で指定してください")

r = csv.reader(sys.stdin)

for row in r:
    for col, pattern in pairs:
        if col < len(row) and pattern.search(row[col]):
            w.writerow(row)
            break  # OR条件なのでマッチしたら次の行へ
' "$@"
}

# 標準入力から CSV を受け取り、見やすくするため区切り行を挟む
csv_sep() {
	_csv_py '
separator = "=" * (int(sys.argv[1]) if len(sys.argv) > 1 else 17)
r = csv.reader(sys.stdin)

for row in r:
    w.writerow(row)
    print(separator)
' "$@"
}

# 標準入力から CSV を受け取り、ヘッダーをキーにして各行を JSON Lines で出力する
csv_json() {
	_csv_py '
r = csv.DictReader(sys.stdin)
for row in r:
    print(json.dumps(dict(row), ensure_ascii=False))
'
}
