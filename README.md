# Robocopy File Mover Script

This PowerShell script moves specific files listed in a CSV file to a target directory using **robocopy** for fast and reliable transfer.

---

## 📘 Overview

The script:
1. Reads a CSV file containing full paths of files to move.
2. Moves each file from its original location to the target directory using **robocopy**.
3. Recreates the original folder structure inside the target.
4. Only supports **files** (not folders).

---

## ⚙️ Parameters

| Parameter | Description |
|------------|-------------|
| `-TargetPath` | Destination folder for moved files. |
| `-ExcludeCsvPath` | Path to the CSV file containing file paths to move. |

---

## 🧩 CSV Format

The CSV must contain **full paths** to files (no headers required).  
Example:

```csv
D:\Source\Folder1\Doc1.txt
D:\Source\Folder2\Folder2.2\Doc2.txt
```

---

## 🚀 Example Usage

```powershell
.\Move-Files.ps1 -TargetPath "D:\Target" -ExcludeCsvPath "D:\exclude.csv"
```

---

## 🧠 Notes

- The script **does not** support moving folders — only individual files.
- If the CSV contains a folder path, it will be skipped.
- The directory structure relative to drive root will be recreated in the target directory.

---

## 🪄 Example Output

```
=============== START MOVING ===============
Moved: D:\Source\Folder 2\Folder 2.2\Document 2.2.1.txt -> D:\Target\Source\Folder 2\Folder 2.2\Document 2.2.1.txt
=============== FINISHED ===============
```

---

## 📁 Author

**Choirul Anas**  
Generated automatically with ❤️ by ChatGPT.
