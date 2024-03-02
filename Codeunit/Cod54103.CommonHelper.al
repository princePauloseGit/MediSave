codeunit 54103 "CommonHelper"
{
    var

        RESTAPIHelper: Codeunit "REST API Helper";
        NYTJSONMgt: Codeunit "NYT JSON Mgt";

    procedure InsertBusinessCentralErrorLog(ExtendedText: text; recordId: Text; enum_EnhIntegrationLogTypes: Enum EnhIntegrationLogTypes; ItemErrorFlag: Boolean; recordType: text; EnhIntegrationLogSeverity: Enum EnhIntegrationLogSeverity; Message: Text)
    var
        rec_EnhanceIntegrationLog: Record EnhancedIntegrationLog;
    begin
        rec_EnhanceIntegrationLog.Init();
        rec_EnhanceIntegrationLog.id := CreateGuid();
        rec_EnhanceIntegrationLog.source := enum_EnhIntegrationLogTypes;
        rec_EnhanceIntegrationLog.Severity := EnhIntegrationLogSeverity;
        rec_EnhanceIntegrationLog.RecordType := recordType;
        rec_EnhanceIntegrationLog.RecordID := recordId;
        rec_EnhanceIntegrationLog.Message := CopyStr(Message, 1, 2048);

        if ItemErrorFlag then begin
            rec_EnhanceIntegrationLog.ExtendedText := CopyStr(ExtendedText, 1, 2048);
            // rec_EnhanceIntegrationLog."Error Message" := CopyStr(errorMessage, 1, 2048);
        end
        else begin
            rec_EnhanceIntegrationLog.ExtendedText := CopyStr(GetLastErrorText(), 1, 2048);
            // rec_EnhanceIntegrationLog."Error Message" := CopyStr(GetLastErrorCallStack(), 1, 2048);
        end;
        rec_EnhanceIntegrationLog.DateTimeOccurred := System.CurrentDateTime;
        rec_EnhanceIntegrationLog.Insert();
    end;

    procedure InsertBusinessCentralErrorLog(errorMessage: text; recordId: Text; enum_EnhIntegrationLogTypes: Enum EnhIntegrationLogTypes; ItemErrorFlag: Boolean; recordType: text)
    var
        rec_EnhanceIntegrationLog: Record EnhancedIntegrationLog;
    begin
        rec_EnhanceIntegrationLog.Init();
        rec_EnhanceIntegrationLog.id := CreateGuid();
        rec_EnhanceIntegrationLog.source := enum_EnhIntegrationLogTypes;
        rec_EnhanceIntegrationLog.Severity := EnhIntegrationLogSeverity::Error;
        rec_EnhanceIntegrationLog.RecordType := recordType;
        rec_EnhanceIntegrationLog.RecordID := recordId;
        rec_EnhanceIntegrationLog.Message := CopyStr(errorMessage, 1, 2048);

        if ItemErrorFlag then begin
            rec_EnhanceIntegrationLog.ExtendedText := CopyStr(errorMessage, 1, 2048);
            rec_EnhanceIntegrationLog."Error Message" := CopyStr(errorMessage, 1, 2048);
        end
        else begin
            rec_EnhanceIntegrationLog.ExtendedText := CopyStr(GetLastErrorText(), 1, 2048);

            rec_EnhanceIntegrationLog."Error Message" := CopyStr(GetLastErrorCallStack(), 1, 2048);
        end;
        rec_EnhanceIntegrationLog.DateTimeOccurred := System.CurrentDateTime;
        rec_EnhanceIntegrationLog.Insert();
    end;

    procedure InsertEnhancedIntegrationLog(varjsonToken: JsonToken; enumEnhIntegrationLogTypes: Enum EnhIntegrationLogTypes; ExtendedText: Text; Severity: Text)
    var
        rec_EnhanceIntegrationLog: Record EnhancedIntegrationLog;
        valueToken: JsonToken;
    begin
        rec_EnhanceIntegrationLog.Init();
        rec_EnhanceIntegrationLog.id := CreateGuid();
        rec_EnhanceIntegrationLog.source := enumEnhIntegrationLogTypes;

        if (severity = 'Information') then begin
            rec_EnhanceIntegrationLog.Severity := EnhIntegrationLogSeverity::Information;
            rec_EnhanceIntegrationLog.RecordID := NYTJSONMgt.GetValueAsText(varjsonToken, 'sku');
            rec_EnhanceIntegrationLog.Message := CopyStr(NYTJSONMgt.GetValueAsText(varjsonToken, 'totalUnits'), 1, 2048);
        end
        else begin
            rec_EnhanceIntegrationLog.Severity := EnhIntegrationLogSeverity::Error;
            rec_EnhanceIntegrationLog.RecordID := ExtendedText;
            rec_EnhanceIntegrationLog.Message := 'Item not found in Surgery Network'
        end;

        rec_EnhanceIntegrationLog.RecordType := 'Stock Update';
        rec_EnhanceIntegrationLog.ExtendedText := ExtendedText;
        rec_EnhanceIntegrationLog.DateTimeOccurred := System.CurrentDateTime;
        rec_EnhanceIntegrationLog.Insert();
    end;

    procedure AddDays(pastDay: Integer; pastDate: Date): Date
    var
        calculatedDate: Date;
        backDay: Text;
    begin
        backDay := '+' + format(pastDay) + 'D';
        exit(CalcDate(backDay, pastDate));
    end;
}
