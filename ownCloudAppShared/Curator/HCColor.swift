import UIKit

public enum HCColor {
	// Constant/Primary
	public static let green = UIColor(hexString: "#6EBD49FF")
	public static let white = UIColor(hexString: "#FFFFFFFF")
	public static let black = UIColor(hexString: "#000000FF")

	public enum Blue {
		// blue/blue darken-1
		public static let darken1 = UIColor(hexString: "#1E88E5FF")
		// blue/blue darken-2
		public static let darken2 = UIColor(hexString: "#1976D2FF")
		// blue/blue lighten-2
		public static let lighten2 = UIColor(hexString: "#64B5F6FF")
		// blue/blue lighten-3
		public static let lighten3 = UIColor(hexString: "#90CAF9FF")
	}

	public enum Grey {
		// grey/grey
		public static let grey = UIColor(hexString: "#9E9E9EFF")
		// grey/grey darken-4
		public static let darken4 = UIColor(hexString: "#212121FF")
		// grey/grey darken-3
		public static let darken3 = UIColor(hexString: "#424242FF")
		// blue/grey lighten-3
		public static let lighten3 = UIColor(hexString: "#EEEEEEFF")
	}

	public enum Transparencies {
		public static let greyDarken3_12 = HCColor.Grey.darken3.withAlphaComponent(0.12)
		public static let blueDarken1_12 = HCColor.Blue.darken1.withAlphaComponent(0.12)
		public static let blueLighten3_12 = HCColor.Blue.lighten3.withAlphaComponent(0.12)
		public static let white_12 = HCColor.white.withAlphaComponent(0.12)
		public static let black_87 = HCColor.black.withAlphaComponent(0.87)
	}

	public enum Text {
		// text/Dark mode/Primary
		public static let darkModePrimary = UIColor(hexString: "#FFFFFFFF")
		// text/Light mode/Primary
		public static let lightModePrimary = HCColor.Transparencies.black_87

		// Content/Text secondary
		public static func secondary(_ isDark: Bool) -> UIColor {
			isDark ? UIColor(hexString: "#FFFFFFB2") : UIColor(hexString: "#00000099")
		}
	}

	public enum Content {
		// Content/Border
		public static func border(_ isDark: Bool) -> UIColor {
			isDark ? UIColor(hexString: "#616161FF") : UIColor(hexString: "#CBCDD3FF")
		}

		// Content/Border 2
		public static func border2(_ isDark: Bool) -> UIColor {
			isDark ? UIColor(hexString: "#616161FF") : UIColor(hexString: "#E0E0E0FF")
		}

		// Content/Text primary
		public static func textPrimary(_ isDark: Bool) -> UIColor {
			isDark ? UIColor(hexString: "#FFFFFFDE") : UIColor(hexString: "#000000DE")
		}

		// Content/Text secondary
		public static func textSecondary(_ isDark: Bool) -> UIColor {
			isDark ? UIColor(hexString: "#FFFFFFB2") : UIColor(hexString: "#00000099")
		}

		// Content/Labels
		public static func labels(_ isDark: Bool) -> UIColor {
			isDark ? UIColor(hexString: "#FFFFFFCC") : UIColor(hexString: "#000000CC")
		}

		// Content/Gray 2
		public static func gray2(_ isDark: Bool) -> UIColor {
			isDark ? UIColor(hexString: "#B2B2B2FF") : UIColor(hexString: "#7A7A7AFF")
		}
		public static let gray3 = UIColor(hexString: "#B2B2B2FF")

		// Content/Disabled BG
		public static func disabledBackground(_ isDark: Bool) -> UIColor {
			isDark ? UIColor(hexString: "#616161FF") : UIColor(hexString: "#EEEEEEFF")
		}

		// Content/SliderBG
		public static func sliderBackground(_ isDark: Bool) -> UIColor {
			isDark ? UIColor(hexString: "#616161FF") : UIColor(hexString: "#E0E0E0FF")
		}

		// Content/Icon Background
		public static func iconBackground(_ isDark: Bool) -> UIColor {
			isDark ? UIColor(hexString: "#64B5F63D") : UIColor(hexString: "#1976D21F")
		}
	}

    public enum Symbolic {
        // Symbolic/Error
        public static func error(_ isDark: Bool) -> UIColor {
            isDark ? UIColor(hexString: "#F28F8CFF") : UIColor(hexString: "#F44336FF")
        }
		// Symbolic/Error Background Transparent
		public static func errorBackgroundTransparent(_ isDark: Bool) -> UIColor {
			isDark ? UIColor(hexString: "#F28F8C3D") : UIColor(hexString: "#F443361F")
		}
    }

	public enum Interaction {
		// Interaction/Primary Solid Normal
		public static func primarySolidNormal(_ isDark: Bool) -> UIColor {
			isDark ? UIColor(hexString: "#64B5F6FF") : UIColor(hexString: "#1976D2FF")
		}
		//Interaction/Primary Transparent Normal 20
		public static func primaryTransparentNormal20(_ isDark: Bool) -> UIColor {
			isDark ? UIColor(hexString: "#64B5F63D") : UIColor(hexString: "#1976D233")
		}
		// Interaction/Secondary Label
		public static func secondaryLabel(_ isDark: Bool) -> UIColor {
			isDark ? UIColor(hexString: "#212121FF") : UIColor(hexString: "#FFFFFFFF")
		}
		// Interaction/Destructive Solid Normal
		public static func destructiveSolidNormal(_ isDark: Bool) -> UIColor {
			isDark ? UIColor(hexString: "#F2918AFF") : UIColor(hexString: "#A02A21FF")
		}
	}

	public enum Structure {
		// Structure/App Background
		public static func appBackground(_ isDark: Bool) -> UIColor {
			isDark ? UIColor(hexString: "#3D3E41FF") : UIColor(hexString: "#F0F1F5FF")
		}
		// Structure/Menu Background
		public static func menuBackground(_ isDark: Bool) -> UIColor {
			isDark ? UIColor(hexString: "#1D1E21FF") : UIColor(hexString: "#FFFFFFFF")
		}
		// Structure/Card Background
		public static func cardBackground(_ isDark: Bool) -> UIColor {
			isDark ? UIColor(hexString: "#262729FF") : UIColor(hexString: "#FFFFFFFF")
		}
		// Structure/White Background
		public static func whiteBackground(_ isDark: Bool) -> UIColor {
			isDark ? UIColor(hexString: "#000000FF") : UIColor(hexString: "#FFFFFFFF")
		}
	}
	public enum Mockups {
		// Mockups/Overlay default
		public static func overlayDefault(_ isDark: Bool) -> UIColor {
			isDark ? UIColor(hexString: "#00000080") : UIColor(hexString: "#00000080")
		}
	}

	public enum Constant {
		// Constant/Primary
		public static func primary(_ isDark: Bool) -> UIColor {
			isDark ? UIColor(hexString: "#6EBD49FF") : UIColor(hexString: "#6EBD49FF")
		}
	}
}
