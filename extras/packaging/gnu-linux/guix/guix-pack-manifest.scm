;;; Copyright (C) 2021-2024 Savoir-faire Linux Inc.
;;;
;;; Author: Maxim Cournoyer <maxim.cournoyer@savoirfairelinux.com>
;;;
;;; This program is free software: you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation, either version 3 of the License, or
;;; (at your option) any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;;
;;; This GNU Guix manifest is used along the Makefile to build the
;;; latest Jami as a Guix pack.

(use-modules (gnu packages)
             (gnu packages certs)
             (gnu packages jami)
             (guix base32)
             (guix gexp)
             (guix packages)
             (guix transformations)
             (guix store)
             (guix utils))

;;; Rather than using something like in the Makefile:
;;;
;;; --with-source=libjami=$(RELEASE_TARBALL_FILENAME) \
;;; --with-source=jami=$(RELEASE_TARBALL_FILENAME)
;;;
;;; the transformations must be made in this manifest file, because
;;; packages from manifest are not affected by input rewriting
;;; options, by design (see: https://issues.guix.gnu.org/61676).

(define %release-version (getenv "RELEASE_VERSION"))

(define %release-file-name (getenv "RELEASE_TARBALL_FILENAME"))

(unless %release-version
  (error "RELEASE_VERSION environment variable is not set"))

(unless %release-file-name
  (error "RELEASE_TARBALL_FILENAME environment variable is not set"))

;;; Add the source tarball to the store and retrieve its hash.  The
;;; hash is useful to turn the origin record into a fixed-output
;;; derivation, which means the Jami packages will only get built once
;;; for a given source tarball.
(define %release-file-hash
  (with-store store
    (let ((source (add-to-store store (basename %release-file-name) #f
                                "sha256" %release-file-name)))
      (bytevector->nix-base32-string (query-path-hash store source)))))

(define %jami-sources/latest
  (origin
    (inherit (@@ (gnu packages jami) %jami-sources))
    (uri %release-file-name)
    (sha256 %release-file-hash)))

;;; 'with-source' cannot currently be combined with 'with-patch' (see:
;;; https://issues.guix.gnu.org/61684).
(define (with-latest-sources name)
  (options->transformation
   `((with-source . ,(format #f "~a@~a=~a" name
                             %release-version %release-file-name))
     ;; XXX: This is not effective, due to the above bug.
     ,@(if (string=? name "libjami")
           `((with-patch . ,(string-append
                             name "="
                             (search-patch
                              "jami-disable-integration-tests.patch"))))
           '()))))

(define libjami/latest
  ((with-latest-sources "libjami")
   (package
     (inherit libjami)
     ;; FIXME: Disable test suite until #61684 above is fixed or the
     ;; 'jami-disable-integration-tests.patch' merged (also see:
     ;; https://git.jami.net/savoirfairelinux/jami-daemon/-/issues/824).
     (arguments (substitute-keyword-arguments (package-arguments libjami)
                  ((#:tests? _ #t)
                   #f))))))

(define with-libjami/latest
  (package-input-rewriting `((,libjami . ,libjami/latest))))

;;; Bundling the TLS certificates with Jami enables a fully
;;; functional, configuration-free experience, useful in the context
;;; of Guix packs.
(define jami-with-certs
  (package/inherit jami
    (inputs (modify-inputs (package-inputs jami)
              (append nss-certs)))
    (arguments
     (substitute-keyword-arguments (package-arguments jami)
       ;; This is necessary due to the missing
       ;; jami-libjami-headers-search.patch patch.
       ((#:configure-flags flags '())
        #~(cons (string-append "-DLIBJAMI_INCLUDE_DIR="
                               #$(this-package-input "libjami")
                               "/include/jami")
                #$flags))
       ((#:phases phases '%standard-phases)
        #~(modify-phases #$phases
            (add-after 'qt-wrap 'wrap-ssl-cert-dir
              (lambda* (#:key inputs outputs #:allow-other-keys)
                (substitute* (search-input-file outputs "bin/jami")
                  (("^exec.*" exec-line)
                   (format #f "export SSL_CERT_DIR=~a~%"
                           (search-input-directory inputs "etc/ssl/certs")
                           exec-line)))))))))))

(define jami-with-certs/latest
  (with-libjami/latest ((with-latest-sources "jami") jami-with-certs)))

(packages->manifest (list jami-with-certs/latest))
