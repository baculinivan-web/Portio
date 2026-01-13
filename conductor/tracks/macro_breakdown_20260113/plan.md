# Plan: Macro Breakdown with Liquid Glass Scroll Effect

## Phase 1: Data Preparation

- [ ] Task: Update `InteractiveMacroCard` to accept an array of `FoodItem` objects
- [ ] Task: Implement a computed property within the card to filter and sort items by their contribution to the specific macro
- [ ] Task: Conductor - User Manual Verification 'Data Preparation' (Protocol in workflow.md)

## Phase 2: Breakdown UI and Scroll Effect

- [ ] Task: Implement the `MacroBreakdownList` component inside the expanded state of `InteractiveMacroCard`
- [ ] Task: Apply `.scrollEdgeEffectStyle(.soft, for: .vertical)` to the breakdown ScrollView
- [ ] Task: Apply a `LinearGradient` mask to the ScrollView to achieve the "soft edge" melting effect
- [ ] Task: Style the individual list rows to match the "Liquid Glass" theme (subtle dividers, refined typography)
- [ ] Task: Conductor - User Manual Verification 'Breakdown UI and Scroll Effect' (Protocol in workflow.md)

## Phase 3: Integration and Polish

- [ ] Task: Update `TodayView` to pass the `items` query result to each `InteractiveMacroCard`
- [ ] Task: Refine expansion animations to account for the new list content
- [ ] Task: Verify end-to-end data flow and visual fidelity
- [ ] Task: Conductor - User Manual Verification 'Integration and Polish' (Protocol in workflow.md)
