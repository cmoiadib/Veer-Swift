# iOS 26 App Development Rules (Swift)

[Design]
- Must strictly follow Liquid Glass design language.
- Only use Apple-provided system materials, blur effects, and colors.
- Light & Dark mode must be supported via system dynamic colors.
- Only use SF Symbols. No custom icons.

[UI]
- Use ONLY native SwiftUI or UIKit components.
- Examples:
  • Button → SwiftUI Button / UIKit UIButton
  • Close (X) → system dismiss controls / UINavigationBar
  • Navigation → NavigationStack (SwiftUI) / UINavigationController (UIKit)
  • Lists → List / UITableView / UICollectionView
  • Text → Text / Label / TextField
- Absolutely NO custom UI components, views, or styles.

[Compatibility]
- Target iOS 26 SDK.
- Follow Apple HIG exactly, no deviations.
- Use only built-in Apple frameworks, no third-party libraries.

[Architecture]
- SwiftUI-first approach. UIKit allowed only if SwiftUI lacks parity.
- Use MVVM for SwiftUI.
- No external dependencies or custom frameworks.

[Accessibility]
- Full compliance with VoiceOver, Dynamic Type, Reduce Motion, High Contrast.
- Always use semantic system components.

[Performance]
- Rely only on Apple-provided animations, transitions, and haptics.
- Use system Material backgrounds (.ultraThinMaterial, .regularMaterial).
- No custom rendering, shaders, or animation curves.

[Interactions]
- Use only system gestures:
  • Swipe-to-go-back
  • Pull-to-refresh (Refreshable)
  • Context menus (ContextMenu)
- Absolutely NO custom gestures.

