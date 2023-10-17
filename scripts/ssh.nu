def main [url: string] {
  rm -rf ./ssh
  git clone $url --depth 1 ./ssh
  cp -r ./ssh/* ~/.ssh
  sudo chmod -R 700 ~/.ssh
  rm -rf ./ssh
}
