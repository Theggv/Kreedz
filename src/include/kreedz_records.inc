#if defined _kreedz_records_included
	#endinput
#endif

#define _kreedz_records_included

enum _:RecordsStruct {
	RecordsTitle[64],
	RecordsList[512],
	RecordsAuthor[32],
	Float:RecordsTime,
	RecordsExtension[16],
};

native Array:kz_records_get_array();
