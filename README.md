<p align="center">
  <img src="assets/app-icon.png" alt="Susu Data Collector App Icon" width="128">
</p>

# Susu Data Collector

Susu Data Collector is a macOS application for our collaborative project to build a high-quality transcription dataset. This tool enables contributors to easily record transcripts for a standardized set of scripts.

## Contributor Workflow

1.  **Build the App**: Follow the "Building from Source" instructions below to run the application on your Mac.
2.  **Record Transcripts**: The app will display a series of scripts one by one. For each script, type your spoken transcript into the text field.
3.  **Save and Continue**: Click "Save & Next" to save your work and move to the next script.
4.  **Complete the Task**: Once you have provided a transcript for every script, the app will show a completion message.

<p align="center">
  <img src="assets/app-screenshot.png" alt="Susu Data Collector App Screenshot" width="600">
</p>

## Submitting Your Data

After completing all the scripts, a `dataset.txt` file will be saved in your computer's **Documents** folder.

Please email this file as an attachment to **tennyson.mccalla@superbuilders.school** so we can include your contributions in our training data.

## Building from Source

To build and run this project from the source code, follow these steps:

1.  **Clone the Repository**:
    ```bash
    git clone https://github.com/your-username/SusuDataCollector.git
    ```
2.  **Open the Project**: Open the `SusuDataCollector.xcodeproj` file in Xcode.
3.  **Build and Run**: Select the "SusuDataCollector" scheme and a macOS target, then click the "Run" button or press `Cmd+R`.
