# innvo
anonymous platform to suggest business projects, made during open hack time @ DEGICA


### Run on local
```
bundle
rackup
```

#### Set ENV var `EMAIL_DOMAIN` to whitelist your teams emails, ex. `degica.com`
#### Need ENV vars in order to send email: `EMAIL_USERNAME` and `EMAIL_PASSWORD`

### Limitations
- Cannot easily assign admin users, currently hardcoded
- Cannot whitelist multiple email domains, single domain allowed currently

### Would like to add
- ENV var to specifiy master admin account
- Admin panel to add remove support admins
- push notifications ???
