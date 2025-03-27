import os
import sys
import subprocess
from transformers import pipeline

# إعداد نموذج الـ AI
classifier = pipeline("text-classification", model="distilbert-base-uncased")

# جمع آخر commits من Git
def get_commits(count=5):
    try:
        result = subprocess.run(
            ['git', 'log', '--oneline', '-n', str(count)],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError:
        return "Error: Git command failed - no commits or repository found"
    except FileNotFoundError:
        return "Error: Git is not installed"

# تحليل الـ commits باستخدام الـ AI
def analyze_commits(commits):
    # تقسيم الـ commits لرسايل منفصلة
    commit_lines = commits.split("\n")
    version_bump = "patch"  # افتراضي

    for line in commit_lines:
        if not line.strip():
            continue
        # استخراج الرسالة بعد الهاش
        message = line.split(" ", 1)[1] if " " in line else line
        # تحليل الرسالة بالـ AI
        result = classifier(message)[0]
        # بنفترض إن النموذج بيرجع label (positive, negative, neutral) ونحولها لـ version
        score = result["score"]
        label = result["label"]

        # تحويل نتيجة الـ AI لقرار إصدار (تخصيص بسيط)
        if "breaking" in message.lower() or (label == "NEGATIVE" and score > 0.9):
            return "major"  # تغيير كبير
        elif "feat" in message.lower() or (label == "POSITIVE" and score > 0.7):
            version_bump = "minor"  # ميزة جديدة
        elif "fix" in message.lower() or (label == "NEUTRAL" and score > 0.7):
            version_bump = "patch"  # تصليح

    return version_bump

# تعديل الإصدار في pubspec.yaml
def update_version(bump):
    filename = "pubspec.yaml"
    if not os.path.exists(filename):
        print("Error: pubspec.yaml not found")
        return
    
    with open(filename, 'r') as file:
        lines = file.readlines()
    
    version_updated = False
    for i in range(len(lines)):
        if lines[i].startswith("version:"):
            current_version = lines[i].split(": ")[1].strip()  # زي "1.0.0"
            parts = [int(x) for x in current_version.split(".")]
            if bump == "major":
                parts[0] += 1
                parts[1] = 0
                parts[2] = 0
            elif bump == "minor":
                parts[1] += 1
                parts[2] = 0
            elif bump == "patch":
                parts[2] += 1
            new_version = ".".join(map(str, parts))
            lines[i] = f"version: {new_version}\n"
            version_updated = True
            break
    
    if version_updated:
        with open(filename, 'w') as file:
            file.writelines(lines)
        print(f"Updated version to: version: {new_version}")
    else:
        print("Error: No 'version:' line found in pubspec.yaml")

# إدارة الأوامر
def main():
    args = sys.argv[1:]

    if "--help" in args or "-h" in args:
        print("Usage: python3 release_manager.py [options]")
        print("Options:")
        print("  --analyze, -a    Analyze commits and update version")
        print("  --help, -h       Show this help message")
        return

    if "--analyze" in args or "-a" in args:
        print("Fetching recent commits...")
        commits = get_commits()
        print(f"Commits:\n{commits}")

        print("Analyzing commits with AI...")
        version_bump = analyze_commits(commits)
        print(f"Suggested version bump: {version_bump}")

        print("Updating pubspec.yaml...")
        update_version(version_bump)
    else:
        print("No action specified. Use --analyze to start or --help for usage.")

if __name__ == "__main__":
    main()