# git-prompt.bash
# 
# A restrained, two-line prompt showing git info when in a repo.
#
# To use colors, set PROMPT_COLORS to anything.
# To use indicator flags for the git parts, set PROMPT_GIT_FLAGS to anything.

# Set these in your .bashrc to override the defaults
PROMPT_COLOR_DEFAULT="${PROMPT_COLOR_DEFAULT:-\x01\e[0;90m\x02}" # dark gray
PROMPT_COLOR_CAUTION="${PROMPT_COLOR_CAUTION:-\x01\e[0;33m\x02}" # brown
PROMPT_COLOR_WARNING="${PROMPT_COLOR_WARNING:-\x01\e[0;31m\x02}" # red

function ansi_reset {
    echo -ne "\x01\e[0m\x02"
}

function prompt_titlebar () {
    if [[ $TERM == @(xterm*|st*|rxvt*) ]]
    then
        echo -ne "\x01\e]2;${PWD} :: ${TERM}\a\x02" 
    fi
}

function prompt_last_exit () {
    local exit_code=$1
    if [[ $exit_code -eq 0 ]]
    then
        echo -ne "^_^"
    else
        [[ -n $PROMPT_COLORS ]] && echo -ne "${PROMPT_COLOR_WARNING}"
        echo -ne "O_o"
        [[ -n $PROMPT_COLORS ]] && echo -ne "${PROMPT_COLOR_DEFAULT}"
    fi
}

function prompt_git_repo_state () {
    local gitstatus="$1"
    local gitdir=$(git rev-parse --absolute-git-dir 2>/dev/null) 
    local name=$(< "${gitdir}/description")
    [[ $name == Unnamed* ]] && name=$(basename $(dirname $gitdir))
    local branch=$(awk '/^# branch.head/{print $3}' <<< "$gitstatus")
    local untracked=$(grep -c '^?' <<< "$gitstatus")
    local unmerged=$(grep -c '^u' <<< "$gitstatus")
    local unstaged=$(grep -c '^\(1\|2\) .[^.]' <<< "$gitstatus")
    local staged=$(grep -c '^\(1\|2\) [^.]' <<< "$gitstatus")
    local state_color=""
    local flag=""
    if [[ $untracked -gt 0 || $unmerged  -gt 0 || $unstaged  -gt 0 ]]
    then
        state_color="$PROMPT_COLOR_WARNING"
        flag="!"
    elif [[ $staged -gt 0 ]]
    then
        state_color="$PROMPT_COLOR_CAUTION"
        flag="*"
    fi
    [[ -n $PROMPT_COLORS ]] && echo -ne "$state_color"
    [[ $name != $(basename $PWD) ]] && echo -ne "$name:"
    echo -ne "$branch"
    [[ -n $PROMPT_GIT_FLAGS ]] && echo -ne "$flag"
    [[ -n $PROMPT_COLORS && -n $state_color ]] &&
        echo -ne "$PROMPT_COLOR_DEFAULT"
}

function prompt_git_remote () {
    local gitstatus="$1"
    grep -q "^# branch.upstream" <<< "$gitstatus" || return
    local ahead=$(awk '/^# branch.ab/{print $3}' <<< "$gitstatus")
    local behind=$(awk '/^# branch.ab/{print $4}' <<< "$gitstatus")
    if [[ $ahead -gt 0 && $behind -lt 0 ]]
    then
        [[ -n $PROMPT_COLORS ]] && echo -ne "$PROMPT_COLOR_WARNING"
        echo -ne "$ahead $behind"
        [[ -n $PROMPT_COLORS ]] && echo -ne "$PROMPT_COLOR_DEFAULT"
    elif [[ $ahead -gt 0 ]]
    then
        [[ -n $PROMPT_COLORS ]] && echo -ne "$PROMPT_COLOR_CAUTION"
        echo -ne "$ahead "
        [[ -n $PROMPT_COLORS ]] && echo -ne "$PROMPT_COLOR_DEFAULT"
        echo -ne "$behind"
    elif [[ $behind -lt 0 ]]
    then
        echo -ne "$ahead "
        [[ -n $PROMPT_COLORS ]] && echo -ne "$PROMPT_COLOR_WARNING"
        echo -ne "$behind"
        [[ -n $PROMPT_COLORS ]] && echo -ne "$PROMPT_COLOR_DEFAULT"
    else
        echo -ne "$ahead,$behind"
    fi
}

function prompt_git_stash () {
    local gitstatus="$1"
    local stashes=$(git stash list)
    [[ -n "$stashes" ]] || return
    local branch=$(awk '/^# branch.head/{print $3}' <<< "$gitstatus")
    if grep -q "" <<< "$stashes"
    then
        [[ -n $PROMPT_COLORS ]] && echo -ne "$PROMPT_COLOR_CAUTION"
        echo -ne "stash"
        [[ -n $PROMPT_GIT_FLAGS ]] && echo -ne "!"
        [[ -n $PROMPT_COLORS ]] && echo -ne "$PROMPT_COLOR_DEFAULT"
    else
        echo -ne "stash"
    fi
}

function prompt_git () {
    local gitstatus
    gitstatus=$(git status --porcelain=v2 --branch 2>/dev/null) || return
    local repo_state=$(prompt_git_repo_state "$gitstatus")
    local remote=$(prompt_git_remote "$gitstatus")
    local stash=$(prompt_git_stash "$gitstatus")
    echo -ne "("
    echo -ne $repo_state
    [[ -n $remote ]] && echo -ne "|$remote"
    [[ -n $stash ]] && echo -ne "|$stash"
    echo -ne ")"
}

function prompt_command () {
    local last_exit=$?
    PS1="$(prompt_titlebar)"
    PS1="${PS1}${PROMPT_COLOR_DEFAULT}"
    PS1="${PS1}┌─$(prompt_last_exit last_exit) \w "
    PS1="${PS1}$(prompt_git)\n"
    PS1="${PS1}${PROMPT_COLOR_DEFAULT}" # fix weird color problem
    PS1="${PS1}└─\A \$"
    PS1="${PS1}$(ansi_reset) "
}

PROMPT_COMMAND=prompt_command

# eof
