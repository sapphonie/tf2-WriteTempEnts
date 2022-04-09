# WriteTempEnts Help Me

reverse engineering mini project (not really i looked at the source lol) of TF2's CBaseClient::WriteTempEntities function

written to debug a crash involving this function

Do Not Use This unless you absolutely know what you are doing.

You probably are looking for this information:

![sv_parallel_sendsnapshot](https://images-ext-1.discordapp.net/external/tyhsPPWPmf48w2UCYY2YRkupBS4U3m06ea6VUdiagTw/https/media.discordapp.net/attachments/959584461035540571/962138064266883142/unknown.png)

TLDR, if you're getting crashes in CBaseClient::WriteTempEntities set

`sv_parallel_sendsnapshot`

and

`sv_parallel_packentities`

to `0` and it will most likely fix your crash!!!
