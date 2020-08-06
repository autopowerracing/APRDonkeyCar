#!/bin/bash

case "$(uname -s)" in
  Darwin)
    mac=1
    shell="$(dscl . -read "/Users/${LOGNAME}" UserShell | awk '{print $NF}')"
    ;;
  Linux)
    linux=1
    shell="$(getent passwd "${LOGNAME}" | cut -d: -f7)"
    ;;
  *)
    echo "Unsupported platform!" >&2
    exit 1
    ;;
esac

is_mac() {
  test -n "${mac}"
}
is_linux() {
  test -n "${linux}"
}

install_prerequisites() {
  if is_mac; then
    install_mac_prereqs    
  elif is_linux; then
    install_linux_prereqs
  fi
  bs_success_message "Installed!"
}

check_executables() {
  packages=("$1")
  missing=""
  for package in $packages; do
    if [[ -z $(which $package) ]]; then
      missing="$missing $package"
    fi
  done
  echo $missing
}

install_mac_prereqs() {
  packages="$(check_executables "git curl brew wget conda")"
  if [[ -n $packages ]]; then
      bs_error_message "will be installing the missing dependencies: $missing"
      for package in $packages; do
        echo "Downloading: $package"
        if [[ $package == "git" ]]; then
          git
        elif [[ $package == "brew" ]]; then
          /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
        elif [[ $package == "wget" ]]; then
          brew install "wget"
        elif [[ $package == "conda" ]]; then
          wget https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh -O ~/miniconda.sh
          bash ~/miniconda.sh -b -p $HOME/miniconda3
          ln -s $HOME/miniconda3/bin/conda /usr/local/bin
        fi
      done
    conda init  # needed before restarting terminal
  fi
}

install_linux_prereqs() {
  packages="$(check_executables "git wget conda")"
  if [[ -n $packages ]]; then
      bs_error_message "will be installing the missing dependencies: $missing"
      for package in $packages; do
        echo "Downloading: $package"
        if [[ $package == "git" ]]; then
          sudo apt-get install git-all
        elif [[ $package == "wget" ]]; then
          sudo apt-get install "wget"
        elif [[ $package == "conda" ]]; then
          wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh          
          bash ~/miniconda.sh -b -p $HOME/miniconda3
        fi
      done
  fi
}

__bs_print_bare_title() {
  local line_color
  line_color="\x1b[36m"
  local padding
  padding="$(__bs_padding "━" "┏")"
  local reset_color
  reset_color="\x1b[0m"
  echo -e "${line_color}┏${padding}${reset_color}"
}
__bs_print_bare_footer() {
  local line_color
  line_color="\x1b[36m"
  local padding
  padding="$(__bs_padding "━" "┗")"
  local reset_color
  reset_color="\x1b[0m"
  echo -e "${line_color}┗${padding}${reset_color}"
}
__bs_print_title() {
  local current_phase
  current_phase=$1; shift
  local n_phases
  n_phases=$1     ; shift
  local title
  title=$1        ; shift
  local line_color title_color reset_color
  line_color="\x1b[36m"
  title_color="\x1b[35m"
  reset_color="\x1b[0m"
  local prefix
  prefix="${line_color}┏━━ 🦄  "
  local text
  text="${prefix}${title_color}${current_phase}/${n_phases}: ${title} "
  local padding
  padding="$(__bs_padding "━" "${text}")"
  echo -e "${text}${line_color}${padding}${reset_color}"
}
__bs_print_fail_footer() {
  local color reset
  color="\x1b[31m"
  reset="\x1b[0m"
  local text
  text="\r${color}┗━━ 💥  Failed! Aborting! "
  local padding
  padding="$(__bs_padding "━" "${text}")"
  echo -e "${text}${padding}${reset}"
}
__bs_padding() {
  local padchar text
  padchar=$1; shift
  text=$1   ; shift
  # ANSI escape sequences (like \x1b[31m) have zero width.
  # when calculating the padding width, we must exclude them.
  local text_without_nonprinting
  text_without_nonprinting="$(
    echo -e "${text}" | sed -E $'s/\x1b\\[[0-9;]+[A-Za-z]//g'
  )"
  local prefixlen
  prefixlen="${#text_without_nonprinting}"
  local termwidth
  termwidth="$(tput cols)"
  local padlen
  ((padlen = termwidth - prefixlen))
  # I don't fully understand what's going on here.
  # It's magic and it works ¯\_(ツ)_/¯
  # Basically though, print N of the padding character,
  # where N is the terminal width minus the width of the text.
  local s
  s="$(printf "%-${padlen}s" "${padchar}")"
  echo "${s// /${padchar}}"
}
__bs_run_func_with_margin() {
  local func
  func=$1; shift
  local prefix_red prefix_green prefix_cyan
  prefix_red=$'s/^/\x1b[31m┃\x1b[0m /'
  prefix_green=$'s/^/\x1b[32m┃\x1b[0m /'
  prefix_cyan=$'s/^/\x1b[36m┃\x1b[0m /'
  (
    set -o pipefail
    { {
    # move stderr to FD 3
    ${func} 8>&2 2>&3 | sed "${prefix_cyan}"
    # prefix output from 3 (relocated stderr) with red
    } 3>&1 1>&2 | sed "${prefix_red}"
    # prefix output from FD 9 with green
    } 9>&1 1>&2 | sed "${prefix_green}"
  )
}
bs_success_message() {
  >&9 echo -e "\x1b[32m✔︎\x1b[0m $1"
}
bs_error_message() {
  >&3 echo -e "\x1b[31m✗\x1b[0m $1"
}

main() {

  __bs_print_title 1 1 "Installing Prerequisites"
  if __bs_run_func_with_margin install_prerequisites; then
    __bs_print_bare_footer
  else
    __bs_print_fail_footer
  fi
}
main
