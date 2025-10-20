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
| `-ListToMovePath` | Path to the CSV file containing file paths to move. |

---

## 🧩 CSV Format

The CSV must contain **full paths** to files (no headers required).  
Example:

```csv
D:\Source\Folder 2\Document 2.1.txt
D:\Source\Folder 2\Document 2.2.txt
D:\Source\Folder 2\Document 2.3.txt
D:\Source\Folder 2\Document 2.4.txt
D:\Source\Folder 2\Document 2.5.txt
```

---

## 🚀 Example Usage

```powershell
.\Move-Files.ps1 -TargetPath "D:\Target" -ListToMovePath "D:\list-to-move.csv"
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
[2025-10-18 19:35:32] [SUCCESS] D:\Source\Folder 2\Document 2.1.txt -> D:\Archive\Source\Folder 2\Document 2.1.txt
[2025-10-18 19:35:32] [SUCCESS] D:\Source\Folder 2\Document 2.2.txt -> D:\Archive\Source\Folder 2\Document 2.2.txt
[2025-10-18 19:35:32] [SUCCESS] D:\Source\Folder 2\Document 2.3.txt -> D:\Archive\Source\Folder 2\Document 2.3.txt
[2025-10-18 19:35:32] [SUCCESS] D:\Source\Folder 2\Document 2.4.txt -> D:\Archive\Source\Folder 2\Document 2.4.txt
[2025-10-18 19:35:32] [SUCCESS] D:\Source\Folder 2\Document 2.5.txt -> D:\Archive\Source\Folder 2\Document 2.5.txt
```

---

## 🧩 Robocopy Exit Code Reference

Exit Code	Meaning	Description
0	No files copied	No changes detected. All files already exist at destination with same timestamp/size.
1	Files copied successfully	All files copied successfully.
2	Extra files deleted	Extra files were deleted (if /PURGE or /MIR used).
3	Files copied + extras deleted	Combination of above.
5–7	Copied + some mismatched/skipped	Minor differences — not necessarily errors.
8+	Serious error	I/O errors, access denied, path not found, etc.

## 📁 Author

**Choirul Anas**  
