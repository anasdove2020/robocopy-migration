# move-files.ps1  
**Author:** Choirul Anas  
**Purpose:** Move files listed in a CSV file to a target directory while preserving their original folder structure.

---

## 📋 Overview
`move-files.ps1` is a PowerShell script that reads file paths from a CSV file and moves each file to a target directory.  
It automatically recreates the original folder structure inside the target directory.

---

## ⚙️ Features
✅ Reads file paths from a CSV file  
✅ Moves files while keeping their full folder structure  
✅ Creates missing directories automatically  
✅ Logs all results (success, warning, or error) to a CSV report  
✅ Displays detailed progress information in the console  

---

## 📂 Input File Format

The input CSV file must contain a column named **`Path`**, for example:

```csv
Path
D:\Source\Folder 1\Document1.txt
D:\Source\Folder 2\Folder 2.1\Document2.txt
D:\Source\Folder 3
```

Each row represents a full file or folder path to move.

---

## 🚀 Usage

### **1. Open PowerShell**
Make sure you open PowerShell **with sufficient permissions** (e.g., Administrator if required).

### **2. Run the Script**

```powershell
.\move-files.ps1 -TargetPath "D:\Target" -ListToMovePath "D:\list-to-move.csv"
```

### **Parameters**

| Parameter | Required | Description |
|------------|-----------|-------------|
| `-TargetPath` | ✅ | Destination folder where files/folders will be moved. |
| `-ListToMovePath` | ✅ | Full path to the CSV file containing file paths to move. |

---

## 🧩 Example

### **Input**
```
TargetPath: D:\Target
ListToMovePath: D:\move-list.csv
```

### **CSV Content**
```csv
Path
D:\Source\Folder 2\Folder 2.2\Document 2.2.1.txt
```

### **Result**
```
=============== START MOVING ===============
[2025-10-18 18:39:49] [  INFO   ] Success to move file from [D:\Source\Folder 2\Document 2.1.txt] to [D:\Archive\Source\Folder 2\Document 2.1.txt]
[2025-10-18 18:39:49] [  INFO   ] Success to move file from [D:\Source\Folder 2\Document 2.3.txt] to [D:\Archive\Source\Folder 2\Document 2.3.txt]
[2025-10-18 18:39:49] [  INFO   ] Success to move file from [D:\Source\Folder 2\Document 2.5.txt] to [D:\Archive\Source\Folder 2\Document 2.5.txt]
```

The script will:
- Automatically create all necessary folders under `D:\Target`
- Move the file while keeping the original folder structure

---

## 🧾 Output

At the end of execution, a summary file named **`MoveResult.csv`** will be generated in the same directory as the script.

### Example content:
```csv
"Timestamp","Status","Source","Destination","Message"
"2025-10-18 18:39:49","SUCCESS","D:\Source\Folder 2\Document 2.1.txt","D:\Archive\Source\Folder 2\Document 2.1.txt","File moved"
"2025-10-18 18:39:49","SUCCESS","D:\Source\Folder 2\Document 2.3.txt","D:\Archive\Source\Folder 2\Document 2.3.txt","File moved"
"2025-10-18 18:39:49","SUCCESS","D:\Source\Folder 2\Document 2.5.txt","D:\Archive\Source\Folder 2\Document 2.5.txt","File moved"
```

---

## ⚠️ Notes
- If a file path does not exist, it will be logged as a **WARNING**.
- Existing files in the target path will be **overwritten** (`-Force` is used).
- Folder structure is preserved relative to the original drive root (e.g., `D:\`).

---

## 🧰 Example Folder Structure

**Before**
```
D:\
 └── Source\
     ├── Folder 1\
     │    └── File1.txt
     └── Folder 2\
          └── Folder 2.1\
               └── File2.txt
```

**After running script**
```
D:\
 └── Target\
      └── Source\
           ├── Folder 1\
           │    └── File1.txt
           └── Folder 2\
                └── Folder 2.1\
                     └── File2.txt
```
