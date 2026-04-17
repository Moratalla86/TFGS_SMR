import os

path = r'c:\Users\Santi\OneDrive\Desktop\DAM2\TFGS_SMR\Frontend\meltic_gmao_app\lib\screens\dashboard_screen.dart'

with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
for i, line in enumerate(lines):
    new_lines.append(line)
    if 'return Card(' in line:
        pass # just tracking
    if '    );' in line and i + 1 < len(lines) and '  Widget _buildAnalyticSummary()' in lines[i+1]:
        print(f"Found insertion point at line {i+1}")
        new_lines.append("  }\n")

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print("Fixed DashboardScreen.dart class structure.")
