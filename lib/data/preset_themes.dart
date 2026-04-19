import 'package:flutter/material.dart';
import '../models/app_theme_profile.dart';

/// Premium preset themes — Crystals, Minerals & Nature collection.
///
/// Design Principles:
/// - No pure black (#000000) or pure white (#FFFFFF)
/// - Background luminance tiers: bgDark < bgCard < bgSurface < bgElevated
/// - For LIGHT themes: bgDark is a tinted mid-ground, bgCard is brighter (cards pop)
/// - Accent triads span different hue families for visual interest
/// - Progress bars use theme-harmonious but distinct colors
/// - Saturation tuned per theme for vibrancy without optical vibration

class PresetThemes {
  PresetThemes._();

  // ═══════════════════════════════════════════════
  //  1. DEFAULT BLUE (Retained — the original)
  //  Harmony: Analogous (blue family)
  // ═══════════════════════════════════════════════
  static final defaultBlue = AppThemeProfile(
    id: 'preset_default',
    name: 'Default Blue',
    bgDark: const Color(0xFF0D1117),
    bgCard: const Color(0xFF161B22),
    bgCardHover: const Color(0xFF1C2333),
    bgSurface: const Color(0xFF21262D),
    bgElevated: const Color(0xFF2D333B),
    accentPrimary: const Color(0xFF58A6FF),
    accentSecondary: const Color(0xFF3FB950),
    accentTertiary: const Color(0xFFD2A8FF),
    accentWarm: const Color(0xFFF78166),
    accentGold: const Color(0xFFE3B341),
    textPrimary: const Color(0xFFF0F6FC),
    textSecondary: const Color(0xFF8B949E),
    textMuted: const Color(0xFF6E7681),
    success: const Color(0xFF3FB950),
    warning: const Color(0xFFD29922),
    error: const Color(0xFFF85149),
    info: const Color(0xFF58A6FF),
    completion: const Color(0xFF1DB954),
    border: const Color(0xFF30363D),
    borderHighlight: const Color(0xFF58A6FF),
    progressProgram: const Color(0xFFE06CCE),
    progressWeek: const Color(0xFF58A6FF),
    progressDay: const Color(0xFF3FB950),
  );

  // ═══════════════════════════════════════════════
  //         D A R K   M O D E  (10 themes)
  // ═══════════════════════════════════════════════

  // ───────────────────────────────────────────────
  //  2. EMERALD — Deep green beryl crystal
  //  Accents: Green → Blue → Coral (triadic spread)
  // ───────────────────────────────────────────────
  static final emerald = AppThemeProfile(
    id: 'preset_emerald',
    name: 'Emerald',
    bgDark: const Color(0xFF0B1A14),
    bgCard: const Color(0xFF122418),
    bgCardHover: const Color(0xFF192E20),
    bgSurface: const Color(0xFF203828),
    bgElevated: const Color(0xFF284232),
    accentPrimary: const Color(0xFF10B981),
    accentSecondary: const Color(0xFF3B82F6),
    accentTertiary: const Color(0xFFFF7E67),
    accentWarm: const Color(0xFFF59E0B),
    accentGold: const Color(0xFFD4AF37),
    textPrimary: const Color(0xFFE8F5EE),
    textSecondary: const Color(0xFF85A694),
    textMuted: const Color(0xFF5A7A68),
    success: const Color(0xFF10B981),
    warning: const Color(0xFFE8B84A),
    error: const Color(0xFFEF4444),
    info: const Color(0xFF3B82F6),
    completion: const Color(0xFF34D399),
    border: const Color(0xFF2A3D32),
    borderHighlight: const Color(0xFF10B981),
    progressProgram: const Color(0xFF10B981),   // Emerald green
    progressWeek: const Color(0xFF3B82F6),      // Sapphire blue
    progressDay: const Color(0xFFFBBF24),       // Gold nugget
  );

  // ───────────────────────────────────────────────
  //  3. AMETHYST — Purple quartz crystal
  //  Accents: Violet → Teal → Rose (split-complementary)
  // ───────────────────────────────────────────────
  static final amethyst = AppThemeProfile(
    id: 'preset_amethyst',
    name: 'Amethyst',
    bgDark: const Color(0xFF12091E),
    bgCard: const Color(0xFF1A1028),
    bgCardHover: const Color(0xFF221832),
    bgSurface: const Color(0xFF2A203C),
    bgElevated: const Color(0xFF342A48),
    accentPrimary: const Color(0xFFA855F7),
    accentSecondary: const Color(0xFF2DD4BF),
    accentTertiary: const Color(0xFFF472B6),
    accentWarm: const Color(0xFFFF8C42),
    accentGold: const Color(0xFFFBBF24),
    textPrimary: const Color(0xFFF0E8FA),
    textSecondary: const Color(0xFF9B8AAE),
    textMuted: const Color(0xFF6D5D82),
    success: const Color(0xFF4ADE80),
    warning: const Color(0xFFFBBF24),
    error: const Color(0xFFF43F5E),
    info: const Color(0xFF818CF8),
    completion: const Color(0xFFD946EF),
    border: const Color(0xFF352C48),
    borderHighlight: const Color(0xFFA855F7),
    progressProgram: const Color(0xFFBF5AF2),   // Crystal violet
    progressWeek: const Color(0xFF2DD4BF),      // Teal shimmer
    progressDay: const Color(0xFFF472B6),       // Rose facet
  );

  // ───────────────────────────────────────────────
  //  4. OBSIDIAN — Volcanic black glass
  //  Accents: Silver → Slate Grey → Ice blue (achromatic + subtle)
  // ───────────────────────────────────────────────
  static final obsidian = AppThemeProfile(
    id: 'preset_obsidian',
    name: 'Obsidian',
    bgDark: const Color(0xFF08080A),
    bgCard: const Color(0xFF111114),
    bgCardHover: const Color(0xFF19191E),
    bgSurface: const Color(0xFF202028),
    bgElevated: const Color(0xFF282830),
    accentPrimary: const Color(0xFF94A3B8),
    accentSecondary: const Color(0xFF475569),
    accentTertiary: const Color(0xFF67E8F9),
    accentWarm: const Color(0xFFE8956A),
    accentGold: const Color(0xFFBEA77C),
    textPrimary: const Color(0xFFF1F5F9),
    textSecondary: const Color(0xFF94A3B8),
    textMuted: const Color(0xFF64748B),
    success: const Color(0xFF4ADE80),
    warning: const Color(0xFFFACC15),
    error: const Color(0xFFEF4444),
    info: const Color(0xFF38BDF8),
    completion: const Color(0xFFF0F0F0),
    border: const Color(0xFF2A2A34),
    borderHighlight: const Color(0xFFE2E8F0),
    progressProgram: const Color(0xFFE2E8F0),   // Volcanic glass shimmer
    progressWeek: const Color(0xFF67E8F9),      // Obsidian ice edge
    progressDay: const Color(0xFFE2E8F0),       // Moonlit silver
  );

  // ───────────────────────────────────────────────
  //  5. SAPPHIRE — Deep blue corundum
  //  Accents: Royal blue → Amber → Orchid (triadic)
  // ───────────────────────────────────────────────
  static final sapphire = AppThemeProfile(
    id: 'preset_sapphire',
    name: 'Sapphire',
    bgDark: const Color(0xFF080E1C),
    bgCard: const Color(0xFF0F1628),
    bgCardHover: const Color(0xFF161E34),
    bgSurface: const Color(0xFF1E2840),
    bgElevated: const Color(0xFF28324C),
    accentPrimary: const Color(0xFF2563EB),
    accentSecondary: const Color(0xFFF59E0B),
    accentTertiary: const Color(0xFFD946EF),
    accentWarm: const Color(0xFFF97316),
    accentGold: const Color(0xFFEAB308),
    textPrimary: const Color(0xFFE8F0FC),
    textSecondary: const Color(0xFF7C92B8),
    textMuted: const Color(0xFF506888),
    success: const Color(0xFF22C55E),
    warning: const Color(0xFFEAB308),
    error: const Color(0xFFEF4444),
    info: const Color(0xFF3B82F6),
    completion: const Color(0xFF60A5FA),
    border: const Color(0xFF253050),
    borderHighlight: const Color(0xFF2563EB),
    progressProgram: const Color(0xFF2563EB),   // Deep sapphire
    progressWeek: const Color(0xFFF59E0B),      // Gold setting
    progressDay: const Color(0xFF22C55E),       // Velvet case green
  );

  // ───────────────────────────────────────────────
  //  6. RUBY — Deep red corundum
  //  Accents: Crimson → Gold → Teal (complementary split)
  // ───────────────────────────────────────────────
  static final ruby = AppThemeProfile(
    id: 'preset_ruby',
    name: 'Ruby',
    bgDark: const Color(0xFF160A0C),
    bgCard: const Color(0xFF201215),
    bgCardHover: const Color(0xFF2A1A1E),
    bgSurface: const Color(0xFF342228),
    bgElevated: const Color(0xFF3E2C32),
    accentPrimary: const Color(0xFFE53E3E),
    accentSecondary: const Color(0xFFEAB308),
    accentTertiary: const Color(0xFF14B8A6),
    accentWarm: const Color(0xFFF59E0B),
    accentGold: const Color(0xFFD4A030),
    textPrimary: const Color(0xFFFEECF0),
    textSecondary: const Color(0xFFAA8088),
    textMuted: const Color(0xFF7A5A62),
    success: const Color(0xFF4ADE80),
    warning: const Color(0xFFF59E0B),
    error: const Color(0xFFDC2626),
    info: const Color(0xFF38BDF8),
    completion: const Color(0xFFF87171),
    border: const Color(0xFF3D2830),
    borderHighlight: const Color(0xFFE53E3E),
    progressProgram: const Color(0xFFE53E3E),   // Ruby fire
    progressWeek: const Color(0xFF14B8A6),      // Cool teal contrast
    progressDay: const Color(0xFFEAB308),       // Gold crown
  );

  // ───────────────────────────────────────────────
  //  7. CITRINE — Golden-yellow quartz
  //  Accents: Amber → Indigo → Coral (complementary)
  // ───────────────────────────────────────────────
  static final citrine = AppThemeProfile(
    id: 'preset_citrine',
    name: 'Citrine',
    bgDark: const Color(0xFF141008),
    bgCard: const Color(0xFF1E1A10),
    bgCardHover: const Color(0xFF282218),
    bgSurface: const Color(0xFF322C20),
    bgElevated: const Color(0xFF3C3628),
    accentPrimary: const Color(0xFFEAB308),
    accentSecondary: const Color(0xFF6366F1),
    accentTertiary: const Color(0xFFFF6B6B),
    accentWarm: const Color(0xFFD97706),
    accentGold: const Color(0xFFFBBF24),
    textPrimary: const Color(0xFFFEFCE8),
    textSecondary: const Color(0xFFA89868),
    textMuted: const Color(0xFF807050),
    success: const Color(0xFF4ADE80),
    warning: const Color(0xFFFBBF24),
    error: const Color(0xFFEF4444),
    info: const Color(0xFF6366F1),
    completion: const Color(0xFFFDE047),
    border: const Color(0xFF3A3428),
    borderHighlight: const Color(0xFFEAB308),
    progressProgram: const Color(0xFFFBBF24),   // Citrine glow
    progressWeek: const Color(0xFF6366F1),      // Deep indigo facet
    progressDay: const Color(0xFFFF6B6B),       // Warm coral spark
  );

  // ───────────────────────────────────────────────
  //  8. MALACHITE — Banded green copper mineral
  //  Accents: Deep green → Bronze → Electric cyan (earth tones)
  // ───────────────────────────────────────────────
  static final malachite = AppThemeProfile(
    id: 'preset_malachite',
    name: 'Malachite',
    bgDark: const Color(0xFF080F0C),
    bgCard: const Color(0xFF101A15),
    bgCardHover: const Color(0xFF18241E),
    bgSurface: const Color(0xFF202E26),
    bgElevated: const Color(0xFF283830),
    accentPrimary: const Color(0xFF059669),
    accentSecondary: const Color(0xFFC2853A),
    accentTertiary: const Color(0xFF22D3EE),
    accentWarm: const Color(0xFFD4884A),
    accentGold: const Color(0xFFB8A04A),
    textPrimary: const Color(0xFFE6F4EC),
    textSecondary: const Color(0xFF7AA08A),
    textMuted: const Color(0xFF507860),
    success: const Color(0xFF059669),
    warning: const Color(0xFFD4A040),
    error: const Color(0xFFDC2626),
    info: const Color(0xFF14B8A6),
    completion: const Color(0xFF34D399),
    border: const Color(0xFF253828),
    borderHighlight: const Color(0xFF059669),
    progressProgram: const Color(0xFF059669),   // Malachite band green
    progressWeek: const Color(0xFFC2853A),      // Copper vein
    progressDay: const Color(0xFF22D3EE),       // Polished turquoise
  );

  // ───────────────────────────────────────────────
  //  9. TANZANITE — Rare blue-violet crystal
  //  Accents: Indigo → Rose → Seafoam (triadic)
  // ───────────────────────────────────────────────
  static final tanzanite = AppThemeProfile(
    id: 'preset_tanzanite',
    name: 'Tanzanite',
    bgDark: const Color(0xFF0A0C18),
    bgCard: const Color(0xFF121624),
    bgCardHover: const Color(0xFF1A1E30),
    bgSurface: const Color(0xFF22283C),
    bgElevated: const Color(0xFF2C3248),
    accentPrimary: const Color(0xFF6366F1),
    accentSecondary: const Color(0xFFF472B6),
    accentTertiary: const Color(0xFF34D399),
    accentWarm: const Color(0xFFFF8C42),
    accentGold: const Color(0xFFFBBF24),
    textPrimary: const Color(0xFFEEF0FC),
    textSecondary: const Color(0xFF8890B0),
    textMuted: const Color(0xFF5C6484),
    success: const Color(0xFF22C55E),
    warning: const Color(0xFFFBBF24),
    error: const Color(0xFFF43F5E),
    info: const Color(0xFF818CF8),
    completion: const Color(0xFF818CF8),
    border: const Color(0xFF2A3050),
    borderHighlight: const Color(0xFF6366F1),
    progressProgram: const Color(0xFF818CF8),   // Tanzanite violet
    progressWeek: const Color(0xFFF472B6),      // Rose inclusion
    progressDay: const Color(0xFF34D399),       // Green flash
  );

  // ───────────────────────────────────────────────
  //  10. ONYX — Black banded chalcedony
  //  Accents: Ember orange → Steel → Lilac (warm mono + pop)
  // ───────────────────────────────────────────────
  static final onyx = AppThemeProfile(
    id: 'preset_onyx',
    name: 'Onyx',
    bgDark: const Color(0xFF0C0C0C),
    bgCard: const Color(0xFF151515),
    bgCardHover: const Color(0xFF1E1E1E),
    bgSurface: const Color(0xFF262626),
    bgElevated: const Color(0xFF303030),
    accentPrimary: const Color(0xFFE06030),
    accentSecondary: const Color(0xFF94A3B8),
    accentTertiary: const Color(0xFFC084FC),
    accentWarm: const Color(0xFFCC5528),
    accentGold: const Color(0xFFD4A840),
    textPrimary: const Color(0xFFEAEAEA),
    textSecondary: const Color(0xFF909094),
    textMuted: const Color(0xFF686870),
    success: const Color(0xFF4ADE80),
    warning: const Color(0xFFD4A840),
    error: const Color(0xFFEF4444),
    info: const Color(0xFF6090B8),
    completion: const Color(0xFFFF6B35),
    border: const Color(0xFF363636),
    borderHighlight: const Color(0xFFE06030),
    progressProgram: const Color(0xFFE06030),   // Onyx ember
    progressWeek: const Color(0xFFC084FC),      // Lilac vein
    progressDay: const Color(0xFF94A3B8),       // Cool steel band
  );

  // ───────────────────────────────────────────────
  //  11. AURORA — Northern lights phenomenon
  //  Accents: Mint → Electric violet → Cyan (aurora spectrum)
  // ───────────────────────────────────────────────
  static final aurora = AppThemeProfile(
    id: 'preset_aurora',
    name: 'Aurora',
    bgDark: const Color(0xFF080E18),
    bgCard: const Color(0xFF101822),
    bgCardHover: const Color(0xFF18222E),
    bgSurface: const Color(0xFF202C3A),
    bgElevated: const Color(0xFF2A3648),
    accentPrimary: const Color(0xFF34D399),
    accentSecondary: const Color(0xFF8B5CF6),
    accentTertiary: const Color(0xFF22D3EE),
    accentWarm: const Color(0xFFE879F9),
    accentGold: const Color(0xFFFBBF24),
    textPrimary: const Color(0xFFE8F2F8),
    textSecondary: const Color(0xFF7E98AA),
    textMuted: const Color(0xFF506878),
    success: const Color(0xFF34D399),
    warning: const Color(0xFFFBBF24),
    error: const Color(0xFFF43F5E),
    info: const Color(0xFF22D3EE),
    completion: const Color(0xFF6EE7B7),
    border: const Color(0xFF253548),
    borderHighlight: const Color(0xFF34D399),
    progressProgram: const Color(0xFF34D399),   // Aurora green curtain
    progressWeek: const Color(0xFF8B5CF6),      // Violet sky band
    progressDay: const Color(0xFF22D3EE),       // Cyan shimmer
  );

  // ═══════════════════════════════════════════════
  //       M O D E R A T E  (5 themes)
  // ═══════════════════════════════════════════════

  // ───────────────────────────────────────────────
  //  12. TIGER'S EYE — Banded golden-brown silicate
  //  Accents: Rich amber → Forest green → Desert sky blue
  // ───────────────────────────────────────────────
  static final tigersEye = AppThemeProfile(
    id: 'preset_tigers_eye',
    name: "Tiger's Eye",
    bgDark: const Color(0xFF2A2018),
    bgCard: const Color(0xFF342A20),
    bgCardHover: const Color(0xFF3E3428),
    bgSurface: const Color(0xFF483E30),
    bgElevated: const Color(0xFF52483A),
    accentPrimary: const Color(0xFFD4943A),
    accentSecondary: const Color(0xFF4CAF50),
    accentTertiary: const Color(0xFF5DADE2),
    accentWarm: const Color(0xFFCC6640),
    accentGold: const Color(0xFFE8B84A),
    textPrimary: const Color(0xFFFAF5EC),
    textSecondary: const Color(0xFFB8A890),
    textMuted: const Color(0xFF8A7A68),
    success: const Color(0xFF5CB87A),
    warning: const Color(0xFFE8B84A),
    error: const Color(0xFFDC4444),
    info: const Color(0xFF5DADE2),
    completion: const Color(0xFFFFAB40),
    border: const Color(0xFF504530),
    borderHighlight: const Color(0xFFD4943A),
    progressProgram: const Color(0xFFD4943A),   // Tiger gold band
    progressWeek: const Color(0xFF4CAF50),      // Forest green stripe
    progressDay: const Color(0xFF5DADE2),       // Desert sky
  );

  // ───────────────────────────────────────────────
  //  13. LABRADORITE — Iridescent feldspar mineral
  //  Accents: Teal → Hot pink → Electric blue (iridescent flash)
  // ───────────────────────────────────────────────
  static final labradorite = AppThemeProfile(
    id: 'preset_labradorite',
    name: 'Labradorite',
    bgDark: const Color(0xFF1A2228),
    bgCard: const Color(0xFF222C34),
    bgCardHover: const Color(0xFF2A3640),
    bgSurface: const Color(0xFF32404C),
    bgElevated: const Color(0xFF3C4A58),
    accentPrimary: const Color(0xFF2DD4BF),
    accentSecondary: const Color(0xFFEC4899),
    accentTertiary: const Color(0xFF38BDF8),
    accentWarm: const Color(0xFFF97316),
    accentGold: const Color(0xFFFBBF24),
    textPrimary: const Color(0xFFECF4F8),
    textSecondary: const Color(0xFF90A8B8),
    textMuted: const Color(0xFF607888),
    success: const Color(0xFF22C55E),
    warning: const Color(0xFFFBBF24),
    error: const Color(0xFFEF4444),
    info: const Color(0xFF38BDF8),
    completion: const Color(0xFF2DD4BF),
    border: const Color(0xFF384858),
    borderHighlight: const Color(0xFF2DD4BF),
    progressProgram: const Color(0xFF2DD4BF),   // Teal labradorescence
    progressWeek: const Color(0xFFEC4899),      // Pink flash
    progressDay: const Color(0xFF38BDF8),       // Electric blue play
  );

  // ───────────────────────────────────────────────
  //  14. GARNET — Deep red silicate mineral
  //  Accents: Wine → Gold → Cool slate blue
  // ───────────────────────────────────────────────
  static final garnet = AppThemeProfile(
    id: 'preset_garnet',
    name: 'Garnet',
    bgDark: const Color(0xFF241418),
    bgCard: const Color(0xFF2E1C22),
    bgCardHover: const Color(0xFF38242C),
    bgSurface: const Color(0xFF422E36),
    bgElevated: const Color(0xFF4C3840),
    accentPrimary: const Color(0xFFD44060),
    accentSecondary: const Color(0xFFEAB308),
    accentTertiary: const Color(0xFF60A5FA),
    accentWarm: const Color(0xFFF59E0B),
    accentGold: const Color(0xFFD4A848),
    textPrimary: const Color(0xFFFAF0F2),
    textSecondary: const Color(0xFFB89098),
    textMuted: const Color(0xFF886870),
    success: const Color(0xFF4ADE80),
    warning: const Color(0xFFEAB308),
    error: const Color(0xFFDC2626),
    info: const Color(0xFF60A5FA),
    completion: const Color(0xFFE87088),
    border: const Color(0xFF4A3238),
    borderHighlight: const Color(0xFFD44060),
    progressProgram: const Color(0xFFD44060),   // Garnet red
    progressWeek: const Color(0xFFEAB308),      // Gold setting
    progressDay: const Color(0xFF60A5FA),       // Cool blue facet
  );

  // ───────────────────────────────────────────────
  //  15. PETRIFIED WOOD — Fossilized ancient timber
  //  Accents: Warm earth → Moss green → Slate blue
  // ───────────────────────────────────────────────
  static final petrifiedWood = AppThemeProfile(
    id: 'preset_petrified_wood',
    name: 'Petrified Wood',
    bgDark: const Color(0xFF22201C),
    bgCard: const Color(0xFF2C2A24),
    bgCardHover: const Color(0xFF36342E),
    bgSurface: const Color(0xFF403E38),
    bgElevated: const Color(0xFF4A4842),
    accentPrimary: const Color(0xFFA07850),
    accentSecondary: const Color(0xFF6AAA60),
    accentTertiary: const Color(0xFF6898B8),
    accentWarm: const Color(0xFFCC7750),
    accentGold: const Color(0xFFBFA04A),
    textPrimary: const Color(0xFFF5F0E8),
    textSecondary: const Color(0xFFA89888),
    textMuted: const Color(0xFF787068),
    success: const Color(0xFF6AAA60),
    warning: const Color(0xFFD4A040),
    error: const Color(0xFFCC5050),
    info: const Color(0xFF6898B8),
    completion: const Color(0xFFBFA04A),
    border: const Color(0xFF48453C),
    borderHighlight: const Color(0xFFA07850),
    progressProgram: const Color(0xFFA07850),   // Petrified bark
    progressWeek: const Color(0xFF6AAA60),      // Ancient moss
    progressDay: const Color(0xFF6898B8),       // Mineral blue
  );

  // ───────────────────────────────────────────────
  //  16. LAPIS LAZULI — Royal blue metamorphic rock
  //  Accents: Deep ultramarine → Pyrite gold → Calcite white
  // ───────────────────────────────────────────────
  static final lapisLazuli = AppThemeProfile(
    id: 'preset_lapis_lazuli',
    name: 'Lapis Lazuli',
    bgDark: const Color(0xFF141828),
    bgCard: const Color(0xFF1C2234),
    bgCardHover: const Color(0xFF242C40),
    bgSurface: const Color(0xFF2E384E),
    bgElevated: const Color(0xFF38425A),
    accentPrimary: const Color(0xFF2D5DD0),
    accentSecondary: const Color(0xFFEAB308),
    accentTertiary: const Color(0xFFE8E0D0),
    accentWarm: const Color(0xFFD4943A),
    accentGold: const Color(0xFFEAB308),
    textPrimary: const Color(0xFFECF0FA),
    textSecondary: const Color(0xFF8898B8),
    textMuted: const Color(0xFF5C6C8A),
    success: const Color(0xFF22C55E),
    warning: const Color(0xFFEAB308),
    error: const Color(0xFFEF4444),
    info: const Color(0xFF2D5DD0),
    completion: const Color(0xFFFBBF24),
    border: const Color(0xFF303C58),
    borderHighlight: const Color(0xFF2D5DD0),
    progressProgram: const Color(0xFF2D5DD0),   // Lapis ultramarine
    progressWeek: const Color(0xFFEAB308),      // Pyrite inclusion
    progressDay: const Color(0xFF22C55E),       // Life green
  );

  // ═══════════════════════════════════════════════
  //       L I G H T   M O D E  (5 themes)
  //  bgDark = tinted mid-ground, bgCard = brighter
  // ═══════════════════════════════════════════════

  // ───────────────────────────────────────────────
  //  17. ROSE QUARTZ — Pale pink silicon dioxide
  //  Accents: Deep rose → Sage green → Slate blue
  // ───────────────────────────────────────────────
  static final roseQuartz = AppThemeProfile(
    id: 'preset_rose_quartz',
    name: 'Rose Quartz',
    bgDark: const Color(0xFFE8D0D4),      // Tinted pink mid-ground
    bgCard: const Color(0xFFFAF2F3),      // Bright card (pops)
    bgCardHover: const Color(0xFFF2E4E6),
    bgSurface: const Color(0xFFEDD8DC),
    bgElevated: const Color(0xFFFCF8F8),
    accentPrimary: const Color(0xFFC93060),
    accentSecondary: const Color(0xFF5E9E6A),
    accentTertiary: const Color(0xFF5A78B0),
    accentWarm: const Color(0xFFE08870),
    accentGold: const Color(0xFFD4A868),
    textPrimary: const Color(0xFF3A1E24),
    textSecondary: const Color(0xFF7A505A),
    textMuted: const Color(0xFFA08088),
    success: const Color(0xFF3D9B5A),
    warning: const Color(0xFFD4A040),
    error: const Color(0xFFCC3030),
    info: const Color(0xFF5A78B0),
    completion: const Color(0xFFE87098),
    border: const Color(0xFFDCC4CA),
    borderHighlight: const Color(0xFFC93060),
    progressProgram: const Color(0xFFC93060),   // Rose heart
    progressWeek: const Color(0xFF5A78B0),      // Cool quartz vein
    progressDay: const Color(0xFF5E9E6A),       // Sage leaf
  );

  // ───────────────────────────────────────────────
  //  18. MOONSTONE — Pearly opalescent feldspar
  //  Accents: Slate blue → Soft coral → Muted violet
  // ───────────────────────────────────────────────
  static final moonstone = AppThemeProfile(
    id: 'preset_moonstone',
    name: 'Moonstone',
    bgDark: const Color(0xFFD8DEE6),      // Cool grey mid-ground
    bgCard: const Color(0xFFF4F6F8),      // Bright pearl card
    bgCardHover: const Color(0xFFE8ECF2),
    bgSurface: const Color(0xFFDEE4EC),
    bgElevated: const Color(0xFFF9FAFB),
    accentPrimary: const Color(0xFF4B5EAA),
    accentSecondary: const Color(0xFFE07860),
    accentTertiary: const Color(0xFF8B6BAA),
    accentWarm: const Color(0xFFA87F71),
    accentGold: const Color(0xFFBEA888),
    textPrimary: const Color(0xFF1A2035),
    textSecondary: const Color(0xFF4A5568),
    textMuted: const Color(0xFF8A94A6),
    success: const Color(0xFF3D9B5E),
    warning: const Color(0xFFD99040),
    error: const Color(0xFFCC4545),
    info: const Color(0xFF4B5EAA),
    completion: const Color(0xFF3D9B5E),
    border: const Color(0xFFCCD4DE),
    borderHighlight: const Color(0xFF4B5EAA),
    progressProgram: const Color(0xFF4B5EAA),   // Moonstone blue
    progressWeek: const Color(0xFFE07860),      // Warm coral glow
    progressDay: const Color(0xFF8B6BAA),       // Opal violet
  );

  // ───────────────────────────────────────────────
  //  19. JADE — Green nephrite mineral
  //  Accents: Jade green → Terracotta → Deep teal
  // ───────────────────────────────────────────────
  static final jade = AppThemeProfile(
    id: 'preset_jade',
    name: 'Jade',
    bgDark: const Color(0xFFCCE0D2),      // Muted jade mid-ground
    bgCard: const Color(0xFFF0F8F2),      // Bright jade card
    bgCardHover: const Color(0xFFDEEEE2),
    bgSurface: const Color(0xFFD2E6D8),
    bgElevated: const Color(0xFFF6FAF7),
    accentPrimary: const Color(0xFF0D8C60),
    accentSecondary: const Color(0xFFC06840),
    accentTertiary: const Color(0xFF0E7490),
    accentWarm: const Color(0xFFD48870),
    accentGold: const Color(0xFFBFA04A),
    textPrimary: const Color(0xFF103028),
    textSecondary: const Color(0xFF386050),
    textMuted: const Color(0xFF689080),
    success: const Color(0xFF0D8C60),
    warning: const Color(0xFFD4A040),
    error: const Color(0xFFCC3838),
    info: const Color(0xFF0E7490),
    completion: const Color(0xFF10B981),
    border: const Color(0xFFC0D6C8),
    borderHighlight: const Color(0xFF0D8C60),
    progressProgram: const Color(0xFF0D8C60),   // Jade vein
    progressWeek: const Color(0xFFC06840),      // Terracotta accent
    progressDay: const Color(0xFF0E7490),       // Deep teal
  );

  // ───────────────────────────────────────────────
  //  20. AMBER — Fossilized resin gemstone
  //  Accents: Rich honey → Forest green → Dusty violet
  // ───────────────────────────────────────────────
  static final amber = AppThemeProfile(
    id: 'preset_amber',
    name: 'Amber',
    bgDark: const Color(0xFFE0D4BC),      // Warm honey mid-ground
    bgCard: const Color(0xFFFAF6EC),      // Bright amber card
    bgCardHover: const Color(0xFFF0EADC),
    bgSurface: const Color(0xFFE6DCC8),
    bgElevated: const Color(0xFFFCFAF4),
    accentPrimary: const Color(0xFFB87018),
    accentSecondary: const Color(0xFF4A8C50),
    accentTertiary: const Color(0xFF8A6AAA),
    accentWarm: const Color(0xFFA05525),
    accentGold: const Color(0xFFC89A30),
    textPrimary: const Color(0xFF352A16),
    textSecondary: const Color(0xFF685838),
    textMuted: const Color(0xFF908060),
    success: const Color(0xFF4A8C50),
    warning: const Color(0xFFD4A020),
    error: const Color(0xFFBB4040),
    info: const Color(0xFF5A80A8),
    completion: const Color(0xFFD4A020),
    border: const Color(0xFFD6CCB0),
    borderHighlight: const Color(0xFFB87018),
    progressProgram: const Color(0xFFB87018),   // Amber resin
    progressWeek: const Color(0xFF4A8C50),      // Trapped leaf green
    progressDay: const Color(0xFF8A6AAA),       // Fossilized violet
  );

  // ───────────────────────────────────────────────
  //  21. AQUAMARINE — Blue-green beryl crystal
  //  Accents: Ocean cyan → Sunset coral → Gold
  // ───────────────────────────────────────────────
  static final aquamarine = AppThemeProfile(
    id: 'preset_aquamarine',
    name: 'Aquamarine',
    bgDark: const Color(0xFFC4DEE6),      // Sea-tinted mid-ground
    bgCard: const Color(0xFFF0F8FA),      // Bright surf card
    bgCardHover: const Color(0xFFD8EEF2),
    bgSurface: const Color(0xFFCCE4EC),
    bgElevated: const Color(0xFFF6FBFC),
    accentPrimary: const Color(0xFF0891B2),
    accentSecondary: const Color(0xFFE87060),
    accentTertiary: const Color(0xFFD4A030),
    accentWarm: const Color(0xFFD48870),
    accentGold: const Color(0xFFD4B478),
    textPrimary: const Color(0xFF122A32),
    textSecondary: const Color(0xFF365A68),
    textMuted: const Color(0xFF648890),
    success: const Color(0xFF22B060),
    warning: const Color(0xFFD4A040),
    error: const Color(0xFFCC4545),
    info: const Color(0xFF0891B2),
    completion: const Color(0xFF06B6D4),
    border: const Color(0xFFBAD4DE),
    borderHighlight: const Color(0xFF0891B2),
    progressProgram: const Color(0xFF0891B2),   // Aquamarine crystal
    progressWeek: const Color(0xFFE87060),      // Coral reef
    progressDay: const Color(0xFFD4A030),       // Sand gold
  );

  /// All preset themes in display order.
  /// Organized: Default → Dark (10) → Moderate (5) → Light (5)
  static final List<AppThemeProfile> all = [
    defaultBlue,
    // Dark Mode
    emerald,
    amethyst,
    obsidian,
    sapphire,
    ruby,
    citrine,
    malachite,
    tanzanite,
    onyx,
    aurora,
    // Moderate
    tigersEye,
    labradorite,
    garnet,
    petrifiedWood,
    lapisLazuli,
    // Light Mode
    roseQuartz,
    moonstone,
    jade,
    amber,
    aquamarine,
  ];
}
