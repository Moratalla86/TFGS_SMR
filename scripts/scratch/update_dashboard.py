import os

path = r'c:\Users\Santi\OneDrive\Desktop\DAM2\TFGS_SMR\Frontend\meltic_gmao_app\lib\screens\dashboard_screen.dart'

with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

target = 'const Text("MONITOREO DE ACTIVOS", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.white70)),'
insertion = """                                   const Text("RENDIMIENTO GLOBAL (KPI)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.white70)),
                                   const SizedBox(height: 12),
                                   _buildAnalyticSummary(),
                                   const SizedBox(height: 30),"""

if target in content:
    # We want to insert AFTER the block following this target.
    # The block following this target is:
    # const SizedBox(height: 12),
    # _buildHorizontalMachineList(_maquinas),
    # const SizedBox(height: 30),
    
    parts = content.split(target)
    after_target = parts[1]
    
    # Find the next 'const SizedBox(height: 30),'
    sub_target = 'const SizedBox(height: 30),'
    sub_parts = after_target.split(sub_target, 1)
    
    if len(sub_parts) > 1:
        new_content = parts[0] + target + sub_parts[0] + sub_target + "\n" + insertion + sub_parts[1]
        with open(path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print("Successfully updated DashboardScreen.dart")
    else:
        print("Could not find sub_target")
else:
    print("Could not find target")
