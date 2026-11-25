// Zellij theme rendered by Omarchy from the active theme's colors.toml.
// Template: ~/.config/omarchy/themed/zellij.kdl.tpl (this file)
// Output:   ~/.local/state/omarchy/current/theme/zellij.kdl
// Linked:   ~/.config/zellij/themes/omarchy.kdl -> the output
// Ported from hyprdots noctalia/templates/zellij-theme.kdl; Material roles
// mapped to Omarchy keys (primary=accent, secondary=magenta, tertiary=green,
// tertiary_container=yellow, error=red, surface_container*=dark/lighter bg).
themes {
    omarchy {
        text_unselected {
            base       "{{ foreground }}"
            background "{{ background }}"
            emphasis_0 "{{ green }}"
            emphasis_1 "{{ magenta }}"
            emphasis_2 "{{ accent }}"
            emphasis_3 "{{ yellow }}"
        }
        text_selected {
            base       "{{ background }}"
            background "{{ foreground }}"
            emphasis_0 "{{ green }}"
            emphasis_1 "{{ magenta }}"
            emphasis_2 "{{ red }}"
            emphasis_3 "{{ yellow }}"
        }

        ribbon_selected {
            base       "{{ background }}"
            background "{{ accent }}"
            emphasis_0 "{{ red }}"
            emphasis_1 "{{ green }}"
            emphasis_2 "{{ yellow }}"
            emphasis_3 "{{ accent }}"
        }
        ribbon_unselected {
            base       "{{ dark_foreground }}"
            background "{{ dark_background }}"
            emphasis_0 "{{ red }}"
            emphasis_1 "{{ lighter_background }}"
            emphasis_2 "{{ selection }}"
            emphasis_3 "{{ muted }}"
        }

        table_title {
            base       "{{ green }}"
            background 0 0 0
            emphasis_0 "{{ yellow }}"
            emphasis_1 "{{ magenta }}"
            emphasis_2 "{{ green }}"
            emphasis_3 "{{ accent }}"
        }
        table_cell_selected {
            base       "{{ foreground }}"
            background "{{ lighter_background }}"
            emphasis_0 "{{ yellow }}"
            emphasis_1 "{{ magenta }}"
            emphasis_2 "{{ green }}"
            emphasis_3 "{{ accent }}"
        }
        table_cell_unselected {
            base       "{{ foreground }}"
            background "{{ background }}"
            emphasis_0 "{{ yellow }}"
            emphasis_1 "{{ magenta }}"
            emphasis_2 "{{ green }}"
            emphasis_3 "{{ accent }}"
        }

        list_selected {
            base       "{{ foreground }}"
            background "{{ lighter_background }}"
            emphasis_0 "{{ yellow }}"
            emphasis_1 "{{ magenta }}"
            emphasis_2 "{{ green }}"
            emphasis_3 "{{ accent }}"
        }
        list_unselected {
            base       "{{ foreground }}"
            background "{{ background }}"
            emphasis_0 "{{ yellow }}"
            emphasis_1 "{{ magenta }}"
            emphasis_2 "{{ green }}"
            emphasis_3 "{{ accent }}"
        }

        frame_selected {
            base       "{{ accent }}"
            background 0 0 0
            emphasis_0 "{{ green }}"
            emphasis_1 "{{ magenta }}"
            emphasis_2 "{{ green }}"
            emphasis_3 0 0 0
        }
        frame_unselected {
            base       "{{ selection }}"
            background 0 0 0
            emphasis_0 "{{ lighter_background }}"
            emphasis_1 "{{ dark_foreground }}"
            emphasis_2 "{{ muted }}"
            emphasis_3 0 0 0
        }
        frame_highlight {
            base       "{{ green }}"
            background 0 0 0
            emphasis_0 "{{ green }}"
            emphasis_1 "{{ green }}"
            emphasis_2 "{{ green }}"
            emphasis_3 "{{ green }}"
        }

        exit_code_success {
            base       "{{ green }}"
            background 0 0 0
            emphasis_0 "{{ magenta }}"
            emphasis_1 0 0 0
            emphasis_2 "{{ yellow }}"
            emphasis_3 "{{ lighter_background }}"
        }
        exit_code_error {
            base       "{{ red }}"
            background 0 0 0
            emphasis_0 "{{ magenta }}"
            emphasis_1 0 0 0
            emphasis_2 0 0 0
            emphasis_3 0 0 0
        }

        multiplayer_user_colors {
            player_1  "{{ yellow }}"
            player_2  "{{ accent }}"
            player_3  "{{ magenta }}"
            player_4  "{{ orange }}"
            player_5  "{{ red }}"
            player_6  "{{ green }}"
            player_7  "{{ cyan }}"
            player_8  "{{ muted }}"
            player_9  "{{ foreground }}"
            player_10 "{{ lighter_background }}"
        }
    }
}
