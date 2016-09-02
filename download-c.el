;;; load-c-src.el --- load C sources for the current Emacs  -*- lexical-binding: t; -*-

;; Copyright (C) 2016  

;; Author: Wilfred Hughes <me@wilfred.me.uk>
;; Keywords: c

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Emacs does not ship with C source code. This is package is to help
;; you fix that.

;;; Code:

(require 'f)
(require 'spinner)

(defun load-c-src--url ()
  "Get a download URL for the source of current Emacs version."
  (format
   "http://ftpmirror.gnu.org/emacs/emacs-%s.%s.tar.gz"
   emacs-major-version emacs-minor-version))

(defvar load-c-src-dir
  (f-expand "~/.emacs.d/src")
  "The directory where we download C sources to.")

(defun load-c-src ()
  "Download C sources for this Emacs, and configure Emacs to use them
with `find-function'."
  (interactive)
  ;; Don't do anything if we're already configured with C sources from somewhere.
  (when find-function-C-source-directory
    (user-error
     (format "Already configured to use C sources in %s"
             find-function-C-source-directory)))
  ;; Ensure the destination directory exists.
  (f-mkdir load-c-src-dir)
  ;; Download the file, asynchronously.
  (let ((url (load-c-src--url))
        (initial-buffer (current-buffer)))
    (spinner-start 'progress-bar)
    (load-c--download-file
     url load-c-src-dir
     (lambda ()
       (with-current-buffer initial-buffer
         (spinner-stop))))))

(defun load-c--download-file (url dest callback)
  "Download URL, saving it DEST. Once completed, call CALLBACK.
Similar to `url-copy-file', but asynchronous.

If DEST is a file, we write directly to that location. If DEST is
a directory, we write the file into that directory, taking the
name from the last part of the URL."
  (let* ((url-callback (lambda (status &rest args)
                         (when (and status (eq (caar status) :error))
                           (user-error (format "Download error: %s" status)))
                         (let (handle)
                           (setq handle (mm-dissect-buffer t))
                           (mm-save-part-to-file handle dest)
                           (kill-buffer (current-buffer))
                           (mm-destroy-parts handle))
                         (funcall callback))))
    ;; If DEST is a directory, we write the file into that directory.
    (when (f-directory? dest)
      (setq dest (f-join dest (f-filename url))))
    (url-retrieve url url-callback)))

(load-c--download-file "http://www.example.com/index.html" "/tmp/"
                       (lambda () (message "downloaded!")))

(provide 'download-c)
;;; download-c.el ends here
