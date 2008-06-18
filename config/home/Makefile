HOME_LINK_FILES = .emacs .viper .profile .cvsrc emacs
MAIL_FILES = .muttrc .mailcap .procmailrc
X_FILES = .xinitrc

install_base: $(HOME_LINK_FILES)
	$(patsubst %, ln -sf $(PWD)/% ~/;, $^)

install_mail: $(MAIL_FILES)
	$(patsubst %, ln -sf $(PWD)/% ~/;, $^)

install_x: $(X_FILES)
	$(patsubst %, ln -sf $(PWD)/% ~/;, $^)
