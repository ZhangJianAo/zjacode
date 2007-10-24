(add-to-list 'load-path "/usr/local/share/emacs/site-lisp")
(add-to-list 'load-path "~/emacs/site-lisp")
(tool-bar-mode nil)

(setq fill-column 80)
;;设置中文环境
(set-language-environment "Chinese-GB")
(set-terminal-coding-system 'chinese-iso-8bit)
(set-keyboard-coding-system 'chinese-iso-8bit)
(set-clipboard-coding-system 'chinese-iso-8bit)
;(set-w32-system-coding-system 'chinese-iso-8bit)
(set-buffer-file-coding-system 'euc-cn)
;(set-buffer-process-coding-system 'chinese-iso-8bit)
;(set-display-coding-system 'euc-china)
(set-selection-coding-system 'euc-cn)

;;部分方便的设置
(setq line-spacing 10)
(setq next-line-add-newlines nil)
(setq column-number-mode t)
(setq line-number-mode t)
(setq inhibit-startup-message t)
(setq-default indent-tabs-mode t)
(setq frame-title-format "emacs %b @ %f")
(setq x-select-enable-clipboard t)

;;部分键绑定
(global-set-key (kbd "C-g") 'goto-line)
(global-set-key [end] 'end-of-line)
(global-set-key [home] 'beginning-of-line)
(global-set-key [C-home] 'beginning-of-buffer)
(global-set-key [C-end] 'end-of-buffer)
(global-set-key (kbd "C-f") 'search-forward-regexp)
(global-set-key [f5] 'compile)
(global-set-key (kbd "M-.") 'cscope-find-this-symbol)
(global-set-key (kbd "M-\r") 'complete-symbol)

;;全局语法加亮
(global-font-lock-mode)
(iswitchb-mode)
(delete-selection-mode)

(defun iswitchb-local-keys ()
  (mapc (lambda (K)
	  (let* ((key (car K)) (fun (cdr K)))
	    (define-key iswitchb-mode-map (edmacro-parse-keys key) fun)))
	'(("<right>" . iswitchb-next-match)
	  ("<left>"  . iswitchb-prev-match))))

(add-hook 'iswitchb-define-mode-map-hook 'iswitchb-local-keys)

;;加载其他附加模块
;(require 'ido)
;(ido-mode t)
(if (require 'color-theme "color-theme" t)
    (color-theme-dark-laptop))

;;方便编辑Scheme程序
;(require 'xscheme)
;(require 'quack)

(defun scheme-send-buffer ()
  "Send the current buffer to the inferior Scheme process."
  (interactive)
;  (scheme-send-region (save-excursion (beginning-of-buffer) (point))
;		      (save-excursion (end-of-buffer) (point))))
(scheme-send-region (point-min) (point-max)))

;(autoload 'run-scheme "xscheme" 
;"Run an inferior Scheme, the way I like it." t) 

;(define-key scheme-mode-map (kbd "<f5>") 'xscheme-send-buffer)

;;使用Delphi Model 来打开Delphi的文件
;(autoload 'delphi-mode "delphi")
;(setq auto-mode-alist
;      (cons '("\\.\\(pas\\|dpr\\|dpk\\)$" . delphi-mode) auto-mode-alist))

;;设置个人的信息
(setq user-full-name "Net Eagle")
(setq user-mail-address "NetEagle@263.net")

;;用%来匹配语法中的括号，可以方便的在括号中移动
(global-set-key "%" 'match-paren)

(defun match-paren (arg)
  "Go to the matching paren if on a paren; otherwise insert %."
  (interactive "p")
  (cond ((looking-at "\\s\(") (forward-list 1) (backward-char 1))
	((looking-at "\\s\)") (forward-char 1) (backward-list 1))
	(t (self-insert-command (or arg 1)))))

;;模拟Windows的设置，用Ctrl+Tab来切换buffer
(global-set-key [C-tab] 'switch-buffer)

(defun switch-buffer (arg)
  "switch buffer ShortCut"
  (interactive "p")
  (switch-to-buffer (other-buffer)))

;;用nxml来编辑xml文件
;(load "nxml/rng-auto.el")
;(setq auto-mode-alist
;        (cons '("\\.\\(xml\\|xsl\\|rng\\|xhtml\\)\\'" . nxml-mode)
;	      auto-mode-alist)) 

;;我常用的文档类型
(add-to-list 'auto-mode-alist '("\\.config\\'" . nxml-mode))
(add-to-list 'auto-mode-alist '("\\.Build\\'" . nxml-mode))
;(add-to-list 'auto-mode-alist '("\\.cs\\'" . csharp-mode))

;;让所有的文件都备份到指定的目录
(setq backup-directory-alist '(("." . "~/.emacs.d/backups")))
;;备份时保留几个版本
(setq version-control t)
(setq kept-new-versions 3)
(setq delete-old-versions t)
(setq kept-old-versions 2)
(setq dired-kept-versions 1)

;;Viper-mode
(setq viper-mode t)
(require 'viper)

;(require 'emacs-wiki)
;(setq emacs-wiki-meta-charset "gb2312")
;; (custom-set-faces
;;   ;; custom-set-faces was added by Custom.
;;   ;; If you edit it by hand, you could mess it up, so be careful.
;;   ;; Your init file should contain only one such instance.
;;   ;; If there is more than one, they won't work right.
;;  )

;; (add-to-list 'load-path (expand-file-name "~/emacs/site-lisp/jde/lisp"))
;; (add-to-list 'load-path (expand-file-name "~/emacs/site-lisp/semantic"))
;; (add-to-list 'load-path (expand-file-name "~/emacs/site-lisp/speedbar"))
;; (add-to-list 'load-path (expand-file-name "~/emacs/site-lisp/elib"))
;; (add-to-list 'load-path (expand-file-name "~/emacs/site-lisp/eieio"))
;; (add-to-list 'load-path "~/emacs/site-lisp/ecb")
;; (require 'ecb)

;; ;; Configuration variables here:
;; (setq semantic-load-turn-useful-things-on t)
;; (require 'semantic-load)

;; (require 'jde)

;(load "python-mode")
;(load "csharp")

;(setq-default compilation-error-regexp-alist
; '(
;;("\\(\\([a-zA-Z]:\\)?[^:(\t\n]+\\)(\\([0-9]+\\)[,]\\([0-9]+\\)): \\(error\\|warning\\) CS[0-9]+:" 1 3 4)
;("\\(.*\\)(\\([0-9]+\\),\\([0-9]+\\)):" 1 2 3)
;))

;(setq-default compilation-nomessage-regexp-alist
; '(("[.*]")))

;(defun my-compilation-filter-hook ()
;   (let ((beg (point))) (backward-line 1) (delete-region beg (point)))
;   (print "zja"))
;(add-hook 'compilatoin-filter-hook 'my-compilation-filter-hook)
;(custom-set-faces
  ;; custom-set-faces was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
; )
(defun run-buffer (arg)
  "run buffer file"
  (interactive "p")
  (print (buffer-file-name))
  (shell-command (buffer-file-name)))

(global-set-key [(f6)] 'run-buffer)


(if (load "php-mode" t)
    (autoload 'php-mode "php-mode" "Mode for editing PHP source files")
    (add-to-list 'auto-mode-alist '("\\.\\(inc\\|php[s34]?\\)" . php-mode))
    (setq c-basic-offset 8))

(require 'xcscope)
