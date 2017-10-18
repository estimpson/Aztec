SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE procedure [dbo].[usp_deleteedidocuments] as

Begin
delete fxEDI.EDI.RawEDIDocuments where RowCreateDT <= (Select DATEADD(day, -90, getdate()))


/*Delete  fxAztec.edi.Dana_830_Headers where RawDocumentGUID not in ( Select RawDocumentGUID From fxAztec.Danaedi.Current830s())
Delete  fxAztec.edi.dana_830_Releases where RawDocumentGUID not in ( Select RawDocumentGUID From fxAztec.Danaedi.Current830s())

Delete  fxAztec.edi.Ford_862_Headers where RawDocumentGUID not in ( Select RawDocumentGUID From fxAztec.Fordedi.Current862s())
Delete  fxAztec.edi.Ford_862_Releases where RawDocumentGUID not in ( Select RawDocumentGUID From fxAztec.Fordedi.Current862s())
*/
end



GO
