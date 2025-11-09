#!/usr/bin/env python3
"""
Remove all Transition-27 (OOCV-27) references from MATLAB script
Systematic removal of redundant decision score model
"""

import re

# Read the file
with open('Precision_Psychiatry_Scripts/Run_Full_Clinical_Associations_Transition_bvFTD.m', 'r') as f:
    content = f.read()

original_length = len(content.splitlines())

# Count occurrences before removal
count_before = len(re.findall(r'(Transition.27|Transition_27|OOCV.27|transition_27|Trans.27)', content, re.IGNORECASE))
print(f"Found {count_before} occurrences of Transition-27 references")

# Track changes
changes = []

# 1. Remove merge section for Transition-27
pattern1 = r"% Merge.*?Transition.*?27.*?\n.*?transition_match_27.*?(?=\n%|\nfprintf|\n\n)"
if re.search(pattern1, content, re.DOTALL | re.IGNORECASE):
    changes.append("Removed Transition-27 merge section")
    content = re.sub(pattern1, '', content, flags=re.DOTALL | re.IGNORECASE)

# 2. Remove standalone Transition_27 assignments
pattern2 = r"analysis_data\.Transition_27 = transition_scores_27\(transition_match_27\);\n"
content = re.sub(pattern2, '', content)
changes.append("Removed Transition_27 data assignment")

# 3. Remove fprintf statements mentioning OOCV-27 or Transition-27
pattern3 = r"fprintf\([^)]*(?:OOCV-27|Transition-27|Trans-27)[^)]*\);\n"
matches3 = re.findall(pattern3, content, re.IGNORECASE)
if matches3:
    changes.append(f"Removed {len(matches3)} fprintf statements about Transition-27")
    content = re.sub(pattern3, '', content, flags=re.IGNORECASE)

# 4. Remove complete variable declarations for _27 variables
pattern4 = r"^\s*\w+_corr_27 = \[\];?\n"
matches4 = re.findall(pattern4, content, re.MULTILINE)
if matches4:
    changes.append(f"Removed {len(matches4)} _27 variable initializations")
    content = re.sub(pattern4, '', content, flags=re.MULTILINE)

# 5. Remove _27 correlation calculation blocks
pattern5 = r"% CORRELATIONS? WITH TRANSITION-27.*?(?=\n%|\n\n\s*%|\nfprintf\('CORR)"
matches5 = re.findall(pattern5, content, re.DOTALL | re.IGNORECASE)
if matches5:
    changes.append(f"Removed {len(matches5)} Transition-27 correlation blocks")
    content = re.sub(pattern5, '', content, flags=re.DOTALL | re.IGNORECASE)

# Count occurrences after removal
count_after = len(re.findall(r'(Transition.27|Transition_27|OOCV.27|transition_27|Trans.27)', content, re.IGNORECASE))
print(f"\n{count_before - count_after} references removed")
print(f"{count_after} references remaining (need manual review)")

# Report changes
print("\nChanges made:")
for i, change in enumerate(changes, 1):
    print(f"  {i}. {change}")

final_length = len(content.splitlines())
print(f"\nLines: {original_length} → {final_length} (removed {original_length - final_length} lines)")

# Write back
# with open('Precision_Psychiatry_Scripts/Run_Full_Clinical_Associations_Transition_bvFTD.m', 'w') as f:
#     f.write(content)

print("\n⚠️  DRY RUN - File not modified")
print("Remove comment in script to actually write changes")
