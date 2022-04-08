#include <sdktools>
#include <dhooks>

Handle hGameData;


public void OnPluginStart()
{
    hGameData = LoadGameConfigFile("tf2.writetempents");
    if (!hGameData)
    {
        SetFailState("Failed to load tf2.writetempents gamedata.");
        return;
    }

    // Load the gamedata file briefly, we only want to cache the "Functions" section.
    Handle hFunctionSigs = LoadGameConfigFile("tf2.writetempents");
    if (!hFunctionSigs)
    {
        SetFailState("Failed to load function-def gamedata");
    }
    delete hFunctionSigs;

    Handle hWriteTempEntsDetour = DHookCreateFromConf(hGameData, "WriteTempEntities");
    if (!hWriteTempEntsDetour)
    {
        SetFailState("Failed to setup detour for WriteTempEntities");
    }

    if (!DHookEnableDetour(hWriteTempEntsDetour, false, Detour_WriteTempEnts))
    {
        SetFailState("Failed to detour WriteTempEntities.");
    }

    PrintToServer("WriteTempEntities detoured!");
}

public MRESReturn Detour_WriteTempEnts(Handle hParams)
{
    // Horrible Evil Bullshit
    // Addr of CBaseClient ptr
    Address pCBaseClient = DHookGetParamAddress(hParams, 1);
    // player index is playerslot+1
    // https://cs.sappho.io/xref/hl2_src/engine/baseclient.cpp#1680
    int iClient = view_as<int>(GetPlayerSlot(pCBaseClient)) + 1;

    Address pCurrentSnapshot    = DHookGetParamAddress(hParams, 2);
    Address pLastSnapshot       = DHookGetParamAddress(hParams, 3);
    Address buf                 = DHookGetParamAddress(hParams, 4);



    PrintToServer("\
        ======================================\n\
        CBaseServer::WriteTempEntities called.\n\
        -   client index                %i\n\
        -  *pCurrentSnapshot            %x\n\
        -  *pLastSnapshot               %x\n\
        -  &buf                         %x\n\
        -   ev_max                      %i\n",
        iClient,
        pCurrentSnapshot,
        pLastSnapshot,
        buf,
        DHookGetParam(hParams, 5));


    // god has punished me for my sins
    // https://cs.sappho.io/xref/hl2_src/engine/framesnapshot.h#64-112

    /*
        ; Attributes: bp-based frame

        ; CFrameSnapshot *__cdecl CFrameSnapshot::CFrameSnapshot(CFrameSnapshot *__hidden this)
        _ZN14CFrameSnapshotC2Ev proc near

        this= dword ptr  8
        ...
        mov     dword ptr [ebx],     0
        mov     dword ptr [ebx+28h], 0
        mov     dword ptr [ebx+2Ch], 0
        mov     dword ptr [ebx+30h], 0
        mov     dword ptr [ebx+34h], 0
        mov     dword ptr [ebx+38h], 0
        mov     dword ptr [ebx+3Ch], 0
        mov     dword ptr [ebx+24h], 0
        mov     dword ptr [ebx+20h], 0
        mov     dword ptr [ebx+10h], 0
        mov     dword ptr [esp+4],   0
    */


    // THIS IS ALL A COMPLETE GUESS I AM NOT LIABLE IF THIS IS WRONG
    // seems accurate tho
    int         m_ListIndex                 = LoadFromAddress(pCurrentSnapshot + view_as<Address>(0x00), NumberType_Int32);
    int         m_nTickCount                = LoadFromAddress(pCurrentSnapshot + view_as<Address>(0x04), NumberType_Int32);
    Address     m_pEntities                 = LoadFromAddress(pCurrentSnapshot + view_as<Address>(0x10), NumberType_Int32);
    int         m_nNumEntities              = LoadFromAddress(pCurrentSnapshot + view_as<Address>(0x20), NumberType_Int32);
    int         m_pValidEntities            = LoadFromAddress(pCurrentSnapshot + view_as<Address>(0x24), NumberType_Int32);
    int         m_nValidEntities            = LoadFromAddress(pCurrentSnapshot + view_as<Address>(0x28), NumberType_Int32);
    Address     m_pHLTVEntityData           = LoadFromAddress(pCurrentSnapshot + view_as<Address>(0x2C), NumberType_Int32);
    Address     m_pReplayEntityData         = LoadFromAddress(pCurrentSnapshot + view_as<Address>(0x30), NumberType_Int32);
    Address     m_ppTempEntities            = LoadFromAddress(pCurrentSnapshot + view_as<Address>(0x34), NumberType_Int32);
    int         m_nTempEntities             = LoadFromAddress(pCurrentSnapshot + view_as<Address>(0x38), NumberType_Int32);
    int         m_iExplicitDeleteSlots      = LoadFromAddress(pCurrentSnapshot + view_as<Address>(0x3C), NumberType_Int32);
    Address     m_nReferences               = LoadFromAddress(pCurrentSnapshot + view_as<Address>(0x60), NumberType_Int32);




    PrintToServer("\
        *pCurrentSnapshot guessed data:   \n\
        -   m_ListIndex                 %i\n\
        -   m_nTickCount                %i\n\
        -  *m_pEntities                 %x\n\
        -   m_nNumEntities              %i\n\
        -  *m_pValidEntities            %x\n\
        -   m_nValidEntities            %i\n\
        -  *m_pHLTVEntityData           %x\n\
        -  *m_pReplayEntityData         %x\n\
        - **m_ppTempEntities            %x\n\
        -   m_nTempEntities             %i\n\
        -   m_iExplicitDeleteSlots      %i\n\
        -  *m_nReferences               %x\n\
        ",
        m_ListIndex,
        m_nTickCount,
        m_pEntities,
        m_nNumEntities,
        m_pValidEntities,
        m_nValidEntities,
        m_pHLTVEntityData,
        m_pReplayEntityData,
        m_ppTempEntities,
        m_nTempEntities,
        m_iExplicitDeleteSlots,
        m_nReferences
);


    return MRES_Ignored;
}


stock any GetPlayerSlot(Address pIClient)
{
    static Handle hPlayerSlot = INVALID_HANDLE;
    if (hPlayerSlot == INVALID_HANDLE)
    {
        StartPrepSDKCall(SDKCall_Raw);
        PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CBaseClient::GetPlayerSlot");
        PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
        hPlayerSlot = EndPrepSDKCall();
    }

    return SDKCall(hPlayerSlot, pIClient);
}