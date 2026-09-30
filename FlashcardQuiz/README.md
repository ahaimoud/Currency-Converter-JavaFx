# Flashcard Quiz (SwiftUI)

A Quizlet-style iOS app: import a CSV or Excel (.xlsx) file of terms and definitions, then quiz yourself.

## Features
- Import `.csv` / `.xlsx` through the Files app document picker (`fileImporter`)
- Column 1 = term, column 2 = definition (a `Term,Definition` header row is auto-skipped)
- Quiz modes: multiple choice or typed answers, in either direction (term→definition or definition→term)
- Progress bar, live score, results screen with percentage, missed-card review and "retry missed"
- Typed answers ignore case, accents, extra spaces and trailing punctuation, with a manual "count it" override

## Requirements
Xcode 15+, iOS 16+ deployment target. Only dependency: [CoreXLSX](https://github.com/CoreOffice/CoreXLSX) (Swift Package Manager). CSV parsing is built in (`Services/CSVParser.swift`), so SwiftCSV isn't needed.

## Setup — Option A: XcodeGen (fastest)
```bash
brew install xcodegen
cd FlashcardQuiz
xcodegen generate
open FlashcardQuiz.xcodeproj
```
Then pick a simulator and press ⌘R.

## Setup — Option B: manual Xcode project
1. Xcode → File → New → Project → iOS **App**. Name it `FlashcardQuiz`, Interface **SwiftUI**, Language **Swift**.
2. Delete the generated `ContentView.swift` and `FlashcardQuizApp.swift`.
3. Drag the contents of the `FlashcardQuiz/FlashcardQuiz` folder (Models, Services, ViewModels, Views, FlashcardQuizApp.swift) into the project navigator ("Copy items if needed" + "Create groups").
4. File → Add Package Dependencies… → `https://github.com/CoreOffice/CoreXLSX` → Up to Next Major from 0.14.1 → add the `CoreXLSX` product to the app target.
5. Build and run (⌘R).

## Testing the import
- Simulator: drag `sample_flashcards.csv` onto the simulator window (it lands in Files → Downloads), then tap **Import File**.
- Real device: AirDrop/iCloud the file, or save an Excel sheet with terms in A and definitions in B.
- Or tap **Try the sample deck** to skip importing.

## Project layout
```
FlashcardQuiz/
├── project.yml                  XcodeGen spec (CoreXLSX dependency)
├── sample_flashcards.csv
└── FlashcardQuiz/
    ├── FlashcardQuizApp.swift   @main entry
    ├── Models/Flashcard.swift   Flashcard, quiz enums, QuizQuestion, sample deck
    ├── Services/
    │   ├── CSVParser.swift      quoted-field-aware CSV parser
    │   ├── XLSXParser.swift     CoreXLSX reader (first sheet, columns A/B)
    │   └── FileImporter.swift   picker types, security-scoped access, file → [Flashcard]
    ├── ViewModels/QuizViewModel.swift  question building, grading, score/progress
    └── Views/
        ├── ContentView.swift        import + deck preview
        ├── QuizContainerView.swift  setup → quiz → results flow, setup screen
        ├── QuizView.swift           question UI
        └── ResultsView.swift        summary
```

## Notes
- Only the first worksheet of an Excel file is read.
- This code was written without access to Xcode in the authoring environment, so it hasn't been compiled here; if Xcode reports a CoreXLSX API mismatch, check the version pinned in `project.yml`.
