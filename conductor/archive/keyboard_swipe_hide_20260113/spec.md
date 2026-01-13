# Specification: Interactive Keyboard Dismissal on Scroll

## Overview
This track implements interactive keyboard dismissal on the main food logging screen. When the user scrolls down the list of food entries, the keyboard will automatically and interactively retract, providing a more fluid and native iOS experience.

## Functional Requirements
- **Interactive Dismissal:**
  - Apply the `.scrollDismissesKeyboard(.interactively)` modifier to the main `List` in `ContentView.swift`.
  - This allows the user to "drag" the keyboard down as they scroll, or have it dismiss automatically on a significant scroll gesture.
- **Context:**
  - This behavior should specifically target the primary interaction area where users are most likely to be typing food queries and then reviewing their history.

## Acceptance Criteria
- [ ] Scrolling the list in `ContentView` while the keyboard is open causes the keyboard to dismiss.
- [ ] The dismissal is interactive (follows the finger/scroll movement).
- [ ] The change does not affect the keyboard behavior in other views (unless intentionally scoped otherwise).
