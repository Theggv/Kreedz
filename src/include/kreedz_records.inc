#if defined _kreedz_records_included
	#endinput
#endif

#define _kreedz_records_included

enum _:RecordsStruct {
	RecordsTitle[64], // source name
	RecordsAuthor[32], // recordholder
	Float:RecordsTime,
	RecordsExtension[16], // additional info (map path)
};

native Array:kz_records_get_array();
