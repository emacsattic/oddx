;;; oddx.el --- extract pages from oddmuse wikis

;; Copyright (C) 2008 Jonas Bernoulli

;; Author: Jonas Bernoulli <jonas@bernoulli.cc>
;; Created: 20081202
;; Updated: 20081202
;; Version: 0.0.1
;; Homepage: https://github.com/tarsius/oddx
;; Keywords: emacswiki

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Extract pages from oddmuse [1] wikis.

;; The perl script `raw.pl' [2] can also convert oddmuse pages to raw
;; pages, but differs in functionality, and can not as easily be used from
;; within Emacs.

;; Unlike `raw.pl' this function forces use of utf-8 coding-system. So the
;; output of `raw.pl' and the function `oddx-extract-page' might differ.

;;; References:

;; [1] http://www.oddmuse.org
;; [2] http://cvs.savannah.gnu.org/viewvc/oddmuse/raw.pl?root=oddx&view=log

;;; Code:

(defun oddx-extract-page (page &optional raw)
  "Extract an oddmuse page file PAGE to raw format file RAW.

PAGE is the oddmuse page file; which can be a wiki page or a source file.

RAW is the file to write the converted page to.  If RAW already exists
it is overwritten.  If RAW is ommited or nil, a string containing the
converted page is returned.  If RAW is t then page is replaced removing
the \".pg\" suffix if needed."
  (let ((enable-local-variables nil)
	(inhibit-auto-compile t)
	(old-buffer (find-buffer-visiting page))
	string delete)
    (with-current-buffer (or old-buffer (find-file-noselect page))
      (goto-char (point-min))
      (setq string (replace-regexp-in-string
		    "^	" ""
		    (buffer-substring-no-properties
		     (re-search-forward "^text: " nil t)
		     (progn (re-search-forward "^[a-z].*: " nil t)
			    (or (re-search-backward "^	.*$" nil t)
				(line-beginning-position))))))
      (unless old-buffer
	(kill-buffer (current-buffer))))
    (if (null raw)
	string
      (when (eq raw t)
	(setq raw (if (string-match "\\.pg$" page)
		      (progn (setq delete t)
			     (substring page 0 -3))
		    page)))
      (setq old-buffer (find-buffer-visiting raw))
      (with-current-buffer (or old-buffer (find-file-noselect raw))
	(erase-buffer)
	(insert string)
	(setq save-buffer-coding-system 'utf-8)
	(let ((inhibit-auto-compile t))
	  (save-buffer))
	(unless old-buffer
	  (kill-buffer (current-buffer))))
      (when delete
	(delete-file page))
      raw)))

(defun oddx-outdated-page (page)
  "Return t if oddmuse page file PAGE is outdated.

Pages are considered to be outdated if they
are marked as deleted or redirect elsewhere."
  (let ((old-buffer (find-buffer-visiting page))
	enable-local-variables
	outdated)
    (with-current-buffer (or old-buffer (find-file-noselect page))
      (goto-char (point-min))
      (re-search-forward "^text: ")
      (setq outdated (re-search-forward "\\(DeletedPage\\|#REDIRECT\\)"
					(line-end-position) t))
      (unless old-buffer
	(kill-buffer (current-buffer))))
    outdated))

(provide 'oddx)
;;; oddx.el ends here
