# Claude Code statusline with real usage from Anthropic API
# Based on: https://gist.github.com/lexfrei/b70aaee919bdd7164f2e3027dc8c98de
{
  writeShellApplication,
  jq,
  curl,
  coreutils,
  ccusage,
  gnused,
}:
writeShellApplication {
  name = "claude-statusline";

  runtimeInputs = [
    jq
    curl
    coreutils
    ccusage
    gnused
  ];

  text = ''
    # Statusline: ccusage base + real quota from Anthropic API

    # Cache settings
    CACHE_FILE="/tmp/claude-usage-cache.json"
    CACHE_TTL=60  # seconds

    # Get cached or fresh usage data
    get_usage() {
        local now
        now=$(date +%s)

        # Check cache
        if [[ -f "$CACHE_FILE" ]]; then
            local cache_time
            cache_time=$(stat -f %m "$CACHE_FILE" 2>/dev/null || stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)
            if (( now - cache_time < CACHE_TTL )); then
                cat "$CACHE_FILE"
                return
            fi
        fi

        # Get credentials from Keychain (macOS) or fallback
        local creds token
        if command -v security &>/dev/null; then
            creds=$(security find-generic-password -s "Claude Code-credentials" -a "$(whoami)" -w 2>/dev/null) || return 1
        else
            return 1
        fi
        token=$(echo "$creds" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null) || return 1

        if [[ -z "$token" ]]; then
            return 1
        fi

        # Fetch usage from API
        local response
        response=$(curl --silent --max-time 5 \
            --header "Authorization: Bearer $token" \
            --header "anthropic-beta: oauth-2025-04-20" \
            "https://api.anthropic.com/api/oauth/usage" 2>/dev/null) || return 1

        # Cache response
        echo "$response" > "$CACHE_FILE"
        echo "$response"
    }

    # Calculate time remaining (in minutes) from ISO timestamp (UTC)
    time_remaining_mins() {
        local reset_at=$1
        local now reset_ts diff

        now=$(date +%s)
        local ts_clean="''${reset_at%%.*}"
        ts_clean="''${ts_clean//T/ }"

        # Try macOS date first, then GNU date
        if date -j &>/dev/null; then
            reset_ts=$(TZ=UTC date -j -f "%Y-%m-%d %H:%M:%S" "$ts_clean" +%s 2>/dev/null) || return 1
        else
            reset_ts=$(TZ=UTC date -d "$ts_clean" +%s 2>/dev/null) || return 1
        fi

        diff=$((reset_ts - now))
        echo $(( diff / 60 ))
    }

    # Format minutes to human readable
    format_time() {
        local mins=$1
        if (( mins <= 0 )); then
            echo "now"
            return
        fi

        local days hours minutes
        days=$((mins / 1440))
        hours=$(((mins % 1440) / 60))
        minutes=$((mins % 60))

        if (( days > 0 )); then
            echo "''${days}d ''${hours}h"
        elif (( hours > 0 )); then
            echo "''${hours}h ''${minutes}m"
        else
            echo "''${minutes}m"
        fi
    }

    # Get rate indicator based on usage% vs time elapsed%
    rate_indicator() {
        local usage=$1
        local remaining_mins=$2
        local total_mins=$3

        local elapsed_mins=$((total_mins - remaining_mins))
        if (( elapsed_mins < 0 )); then elapsed_mins=0; fi

        local time_pct
        if (( total_mins > 0 )); then
            time_pct=$((elapsed_mins * 100 / total_mins))
        else
            time_pct=0
        fi

        local diff=$((usage - time_pct))

        if (( diff <= 0 )); then
            echo "🟢"
        elif (( diff <= 5 )); then
            echo "🟡"
        elif (( diff <= 15 )); then
            echo "🟠"
        else
            echo "🔴"
        fi
    }

    # Main - receives JSON from Claude Code via stdin
    main() {
        local input
        input=$(cat)

        # Get base statusline from ccusage
        local base
        base=$(echo "$input" | ccusage statusline --offline --visual-burn-rate off 2>/dev/null) || base=""

        # Strip fields we replace with real API data
        base=$(echo -e "$base" | sed -E 's/ *\([0-9]+h [0-9]+m left\)//g; s| */ *\$[0-9]+\.[0-9]+ block||g; s| */ *No active block||g; s/\| *🧠 [^|]*//g')
        base=$(echo -e "$base" | sed -E 's/[| ]+$//')

        # Add real context usage from Claude Code stdin
        local ctx_pct
        ctx_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty' 2>/dev/null)
        if [[ -n "$ctx_pct" ]]; then
            ctx_pct=$(printf "%.0f" "$ctx_pct")
            local ctx_color="\033[32m"  # green
            if (( ctx_pct >= 80 )); then
                ctx_color="\033[31m"    # red
            elif (( ctx_pct >= 50 )); then
                ctx_color="\033[33m"    # yellow
            fi
            base="''${base} | ''${ctx_color}🧠 ''${ctx_pct}%\033[0m"
        fi

        # Get usage data from API
        local usage
        usage=$(get_usage 2>/dev/null) || usage=""

        # Check for API errors
        local api_error=""
        if [[ -n "$usage" ]]; then
            api_error=$(echo "$usage" | jq -r '.error.type // empty' 2>/dev/null)
        fi

        if [[ -n "$api_error" ]]; then
            echo "''${base} | ⚠️ /login needed"
        elif [[ -n "$usage" ]]; then
            local five_hour five_hour_resets seven_day seven_day_resets
            five_hour=$(echo "$usage" | jq -r '.five_hour.utilization // empty' 2>/dev/null)
            five_hour_resets=$(echo "$usage" | jq -r '.five_hour.resets_at // empty' 2>/dev/null)
            seven_day=$(echo "$usage" | jq -r '.seven_day.utilization // empty' 2>/dev/null)
            seven_day_resets=$(echo "$usage" | jq -r '.seven_day.resets_at // empty' 2>/dev/null)

            local quota_info=""

            # 7d always shown
            if [[ -n "$seven_day" ]]; then
                local seven_day_int seven_day_remaining_mins seven_day_indicator seven_day_time_str
                seven_day_int=$(printf "%.0f" "$seven_day")
                seven_day_remaining_mins=$(time_remaining_mins "$seven_day_resets" 2>/dev/null) || seven_day_remaining_mins=0
                seven_day_indicator=$(rate_indicator "$seven_day_int" "$seven_day_remaining_mins" 10080)
                seven_day_time_str=$(format_time "$seven_day_remaining_mins")
                quota_info+="''${seven_day_indicator} 7d: ''${seven_day_int}% (''${seven_day_time_str})"
            fi

            # 5h always shown
            if [[ -n "$five_hour" ]]; then
                local five_hour_int five_hour_remaining_mins five_hour_indicator five_hour_time_str
                five_hour_int=$(printf "%.0f" "$five_hour")
                five_hour_remaining_mins=$(time_remaining_mins "$five_hour_resets" 2>/dev/null) || five_hour_remaining_mins=0
                five_hour_indicator=$(rate_indicator "$five_hour_int" "$five_hour_remaining_mins" 300)
                five_hour_time_str=$(format_time "$five_hour_remaining_mins")

                [[ -n "$quota_info" ]] && quota_info+=" | "
                quota_info+="''${five_hour_indicator} 5h: ''${five_hour_int}% (''${five_hour_time_str})"
            fi

            if [[ -n "$quota_info" ]]; then
                echo -e "''${base} | ''${quota_info}"
            else
                echo -e "$base"
            fi
        else
            echo -e "$base"
        fi
    }

    main
  '';
}
