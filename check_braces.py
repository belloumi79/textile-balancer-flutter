content = open('lib/screens/dashboard_screen.dart', 'r', encoding='utf-8').read()
lines = content.split('\n')
balance = 0
for i, line in enumerate(lines, 1):
    balance += line.count('{') - line.count('}')
    if balance < 0:
        print(f'Line {i}: balance={balance}: {line.strip()}')
print(f'Final balance: {balance}')