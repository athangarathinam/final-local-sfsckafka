#!/bin/bash
curl -Ss https://cli-assets.heroku.com/install.sh | sh
# sudo sh ./install.sh

cat > ~/.netrc << EOF
machine api.heroku.com
  login $HEROKU_LOGIN
  password $HEROKU_TOKEN
EOF

cat >> ~/.ssh/config << EOF
VerifyHostKeyDNS yes
StrictHostKeyChecking no
EOF
chmod 600 ~/.netrc
