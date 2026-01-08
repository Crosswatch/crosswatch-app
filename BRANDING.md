# Crosswatch Brand Guidelines

## Color Palette

### Primary Colors

**Electric Blue** - Primary brand color
- Hex: `#1E88E5`
- RGB: `rgb(30, 136, 229)`
- Use: Primary actions, app bar, main UI elements

**Vibrant Coral** - Secondary accent
- Hex: `#FF6B6B`
- RGB: `rgb(255, 107, 107)`
- Use: Secondary actions, container sets, pause state, highlights

**Neon Lime** - Success/completion accent
- Hex: `#00E676`
- RGB: `rgb(0, 230, 118)`
- Use: Success states, completed exercises, rep-based exercises, timer markers

### Dark Theme Colors

**Dark Navy** - Background
- Hex: `#0A1929`
- RGB: `rgb(10, 25, 41)`
- Use: Main background for dark mode

**Navy Surface** - Surface color
- Hex: `#132F4C`
- RGB: `rgb(19, 47, 76)`
- Use: Cards, elevated surfaces in dark mode

### Usage Guidelines

#### Timer States
- **Transition/Preparation**: Electric Blue `#1E88E5`
- **Active (Time-based)**: Vibrant Coral `#FF6B6B`
- **Active (Rep-based)**: Neon Lime `#00E676`

#### UI Elements
- **Container Sets**: Vibrant Coral `#FF6B6B`
- **Individual Exercises**: Electric Blue `#1E88E5`
- **Success States**: Neon Lime `#00E676`

#### Buttons
- **Play/Start**: Neon Lime `#00E676`
- **Pause**: Vibrant Coral `#FF6B6B`
- **Primary Actions**: Electric Blue `#1E88E5`

## Logo

### Design Concept
The Crosswatch logo features a stylized stopwatch with an integrated "X" representing cross-training and high-intensity workouts.

**Elements:**
- Circular stopwatch body in Electric Blue gradient
- Stylized "X" in the center using Vibrant Coral
- Timer markers at 12, 3, 6, 9 o'clock positions in Neon Lime
- Crown/button at top for authenticity

**Files:**
- SVG: `assets/branding/logo.svg`
- PNG (1024x1024): `assets/branding/icon.png`

### Logo Variations
- **Full Logo**: Use for splash screens, about pages
- **Icon Only**: Generated launcher icons for app icon

## Typography

**Primary Font**: System Default (Roboto on Android, SF Pro on iOS)
- **Headings**: Bold, size 20-24
- **Body**: Regular, size 14-16
- **Captions**: Regular, size 12-14

**Timer Display**: Bold, large (60-80pt) for countdown numbers

## Iconography

**Icon Style**: Material Design Icons
- Use outlined icons for inactive states
- Use filled icons for active/selected states

**Common Icons:**
- `fitness_center` - Individual exercises
- `folder` - Container sets
- `timer` - Time-based exercises
- `repeat` - Rep-based exercises
- `play_arrow` - Start
- `pause` - Pause
- `stop` - Stop/Complete

## Spacing & Layout

**Padding:**
- Screen edges: 16px
- Card padding: 16px
- List item padding: 12px vertical, 16px horizontal

**Border Radius:**
- Cards: 12px
- Buttons: 8px
- Badges: 12px

**Elevation:**
- Cards (light mode): 2dp
- Cards (dark mode): 4dp
- FAB: 6dp

## Accessibility

**Color Contrast:**
- Text on Electric Blue background: White text (WCAG AA compliant)
- Text on Vibrant Coral background: White text (WCAG AA compliant)
- Text on Neon Lime background: Dark text or white with transparency

**Interactive Elements:**
- Minimum touch target: 48x48dp
- Clear visual feedback on tap
- Sufficient color contrast for all states

## Animation

**Duration:**
- Fast transitions: 150ms
- Normal transitions: 300ms
- Slow transitions: 500ms

**Easing:**
- Standard: `cubic-bezier(0.4, 0.0, 0.2, 1)`
- Deceleration: `cubic-bezier(0.0, 0.0, 0.2, 1)`
- Acceleration: `cubic-bezier(0.4, 0.0, 1, 1)`

## Implementation

### Flutter Theme
Colors are implemented in `lib/main.dart` using Material 3 ColorScheme:

```dart
ColorScheme.fromSeed(
  seedColor: const Color(0xFF1E88E5), // Electric Blue
  secondary: const Color(0xFFFF6B6B), // Vibrant Coral
  tertiary: const Color(0xFF00E676), // Neon Lime
  brightness: Brightness.light, // or Brightness.dark
)
```

### Accessing Theme Colors
Always use theme colors instead of hardcoded values:

```dart
// Good
Theme.of(context).colorScheme.primary
Theme.of(context).colorScheme.secondary
Theme.of(context).colorScheme.tertiary

// Bad
Colors.blue
const Color(0xFF1E88E5)
```

## Brand Voice

**Tone:** Energetic, motivating, direct, supportive
**Personality:** Coach-like, encouraging, performance-focused
**Language:** Active verbs, clear instructions, positive reinforcement

**Examples:**
- "Let's crush this workout!" ✓
- "You can do it!" ✓
- "Great job completing that round!" ✓
- "Please complete the form." ✗ (too formal)

## Platform-Specific Considerations

### Android
- Use Material Design 3 components
- Support dark theme based on system settings
- Adaptive icons with transparent background
- Use system navigation gestures

### iOS
- Follow Human Interface Guidelines where appropriate
- Support both light and dark modes
- Use SF Symbols for iOS-specific icons
- Respect safe areas and notches

### Desktop (Linux/Windows/macOS)
- Larger touch targets for mouse interaction
- Keyboard shortcuts for common actions
- Window chrome follows platform conventions
- Menu bar integration on macOS

---

**Version:** 1.0  
**Last Updated:** January 2026  
**Contact:** Crosswatch Brand Team
