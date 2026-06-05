# 標準入力から CSV を受け取り、ヘッダーを表示する
csv_head() {
	python3 -c '
import csv, sys, signal
signal.signal(signal.SIGPIPE, signal.SIG_DFL)  # BrokenPipeError防止

r = csv.reader(sys.stdin)
for i, h in enumerate(next(r)):
    print(f"{i+1:02}: {h}")
'
}

# 標準入力から CSV を受け取り、列名を引数で指定して表示する
csv_cut() {
	python3 -c '
import csv, sys, signal
signal.signal(signal.SIGPIPE, signal.SIG_DFL)  # BrokenPipeError防止

cols = sys.argv[1:]
r = csv.DictReader(sys.stdin)
w = csv.writer(sys.stdout, lineterminator="\n")

w.writerow(cols)
for row in r:
    w.writerow([row.get(c, "") for c in cols])
' "$@"
}

# 標準入力から CSV を受け取り、列番号を引数で指定して表示する
csv_cutn() {
	python3 -c '
import csv, sys, signal
signal.signal(signal.SIGPIPE, signal.SIG_DFL)  # BrokenPipeError防止

cols = [int(c) - 1 for c in sys.argv[1:]]
r = csv.reader(sys.stdin)
w = csv.writer(sys.stdout, lineterminator="\n")

for row in r:
    w.writerow([row[c] if c < len(row) else "" for c in cols])
' "$@"
}

# 標準入力から CSV を受け取り、指定した行数までを出力
csv_limit() {
	python3 -c '
import sys, csv, signal
signal.signal(signal.SIGPIPE, signal.SIG_DFL)  # BrokenPipeError防止

limit = int(sys.argv[1]) if len(sys.argv) > 1 else 10
r = csv.reader(sys.stdin)
w = csv.writer(sys.stdout, lineterminator="\n")

for i, row in enumerate(r):
    if i >= limit:
        break
    w.writerow(row)
' "$@"
}

# 標準入力から CSV を受け取り、先頭N行をスキップして出力する
csv_skip() {
	python3 -c '
import sys, csv, signal
signal.signal(signal.SIGPIPE, signal.SIG_DFL)  # BrokenPipeError防止

skip = int(sys.argv[1]) if len(sys.argv) > 1 else 1
r = csv.reader(sys.stdin)
w = csv.writer(sys.stdout, lineterminator="\n")

for _ in range(skip):
    next(r, None)

for row in r:
    w.writerow(row)
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
	python3 -c '
import sys, csv, re, signal
signal.signal(signal.SIGPIPE, signal.SIG_DFL)

args = sys.argv[1:]
if len(args) < 2 or len(args) % 2 != 0:
    print("Usage: csv_grep col1 regex1 [col2 regex2 ...]", file=sys.stderr)
    sys.exit(1)

# カラム名と正規表現のペアをリスト化
pairs = [(args[i], args[i+1]) for i in range(0, len(args), 2)]

r = csv.DictReader(sys.stdin)
w = csv.writer(sys.stdout, lineterminator="\n")

# 出力ヘッダ
w.writerow(r.fieldnames)

for row in r:
    for col, pattern in pairs:
        if col in row and re.search(pattern, row[col] or ""):
            w.writerow([row[c] for c in r.fieldnames])
            break  # OR条件なのでマッチしたら次の行へ
' "$@"
}
# カラム名ではなく列番号
csv_grepn() {
	python3 -c '
import sys, csv, re, signal
signal.signal(signal.SIGPIPE, signal.SIG_DFL)

args = sys.argv[1:]
if len(args) < 2 or len(args) % 2 != 0:
    print("Usage: csv_grepn colnum1 regex1 [colnum2 regex2 ...]", file=sys.stderr)
    sys.exit(1)

# カラム番号と正規表現のペア（1始まり → 0始まりへ変換）
pairs = [(int(args[i]) - 1, args[i+1]) for i in range(0, len(args), 2)]

r = csv.reader(sys.stdin)
w = csv.writer(sys.stdout, lineterminator="\n")

for row in r:
    for col, pattern in pairs:
        if col < len(row) and re.search(pattern, row[col] or ""):
            w.writerow(row)
            break  # OR条件なのでマッチしたら次の行へ
' "$@"
}

# 標準入力から CSV を受け取り、見やすくするため区切り行を挟む
csv_sep() {
	python3 -c '
import sys, csv, signal
signal.signal(signal.SIGPIPE, signal.SIG_DFL)  # BrokenPipeError防止

separator = int(sys.argv[1]) if len(sys.argv) > 1 else "================="
r = csv.reader(sys.stdin)
w = csv.writer(sys.stdout, lineterminator="\n")

for row in r:
    w.writerow(row)
    print(separator)
' "$@"
}
