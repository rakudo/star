#! /usr/bin/env sh

readonly DISTNAME="rakudo-star-$CI_COMMIT_REF_NAME"

main()
{
	if list_releases | grep -Fq "$DISTNAME"
	then
		printf "A release named %s already exists!\n" "$DISTNAME"
		exit 1
	fi

	upload_release
}

list_releases()
{
	lftp -e <<-EOI
	open $FTP_HOST:${FTP_PORT:-21};
	user sftp://$FTP_USER $FTP_PASSWORD;
	cd ${FTP_DIR:-rakudo-star};
	ls;
	bye;
	EOI
}

upload_release()
{
	lftp -e <<-EOI
	open $FTP_HOST:${FTP_PORT:-21};
	user sftp://$FTP_USER $FTP_PASSWORD;
	cd ${FTP_DIR:-rakudo-star};
	put work/release/rakudo-star-$CI_COMMIT_REF_NAME;
	bye;
	EOI
}

main "$@"
