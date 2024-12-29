import os
  
folders = input("please provide the list of folders with spaces in between: ").split()

for folder in folders:
  try:
    files = os.listdir(folder)
  except FileNotFoundError:
    print("\nFolder is not a valid folder name -" + folder)
    continue
  print("\nShow the list of files in -" + folder)
  print("\n")
  for file in files:
    print(file)
