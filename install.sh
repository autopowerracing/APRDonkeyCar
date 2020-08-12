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

install_donkeycar() {
  # confirm that you are at the root directory
  echo "Activating base enviroment."
  conda activate

  if conda env list | grep -q donkey; then
    echo "Found Existing donkey enviroment. Updating...."
    conda update -n base -c defaults conda -y
    conda env remove -n donkey
  fi

  if is_mac; then
    conda env create -f ./donkeycar/install/envs/mac.yml
  elif is_linux; then
    conda env create -f ./donkeycar/install/envs/ubuntu.yml
  fi

  echo "Activating donkey enviroment."
  conda activate donkey
  pip install -e donkeycar/
}

install_gymdonkeycar() {
  echo "Activating gym donkey enviroment"
  conda activate donkey
  pip install -e gym-donkeycar/
}

create_donkeycar_app() {
  conda activate donkey
  if [ ! -d "./mycar" ]; then 
    donkey createcar --path mycar
  else
    echo "You already have the default donkeycar app"
  fi
}

download_simulation() {
  if [ ! -d "./Simulator-Binaries" ]; then
    echo "Downloading latest Simulator Binary"
    mkdir ./Simulator-Binaries

    if is_mac; then
      system="Mac"
    elif is_linux; then
      system="Linux"
    fi

    # system="Mac"
    echo "On $system"

    # ids of releases
    # August  29014167
    # May     26596667
    release_id=26596667

    # getting url of binary
    downloadUrl=$(curl -s "https://api.github.com/repos/tawnkramer/gym-donkeycar/releases/$release_id" \
    | grep "browser_download_url.*$system*.zip" \
    | cut -d '"' -f 4)
    
    # binaryUrl=$(echo $downloadUrls | grep -i $system | cut -d '"' -f 4)
    echo "Downloading binary from $downloadUrl"
    wget $downloadUrl -P ./Simulator-Binaries/ --quiet --show-progress
    
    # unzip and delete zip folder
    zipName=$(ls ./Simulator-Binaries/*.zip)
    pwd
    unzip $zipName -d ./Simulator-Binaries
    rm $zipName
  else 
    echo "You already have a binary"
  fi
}

check_executables() {
  packages=("$1")
  missing=""
  for package in $packages; do
    if [[ -z $(which $package) ]]; then
      # bs_error_message "$package not installed"
      missing="$missing $package"
    fi
  done
  echo $missing
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

  __bs_print_title 1 4 "Installing DonkeyCar"
  if __bs_run_func_with_margin install_donkeycar; then
    __bs_print_bare_footer
  else
    __bs_print_fail_footer
  fi

  __bs_print_title 2 4 "Installing GYM Donkeycar"
  if __bs_run_func_with_margin install_gymdonkeycar; then
    __bs_print_bare_footer
  else
    __bs_print_fail_footer
  fi

  __bs_print_title 3 4 "Downloading Simulator Binaries"
  if __bs_run_func_with_margin download_simulation; then
    __bs_print_bare_footer
  else
    __bs_print_fail_footer
  fi

  __bs_print_title 4 4 "Creating First App"
  if __bs_run_func_with_margin create_donkeycar_app; then
    __bs_print_bare_footer
  else
    __bs_print_fail_footer
  fi
}
main
