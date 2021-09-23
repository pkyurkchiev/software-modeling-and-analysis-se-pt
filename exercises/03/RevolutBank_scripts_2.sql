CREATE VIEW vw_GetCardWithBankAccounts AS
SELECT ca.CardNumber, ca.CardType, ca.ValidationDate AS CardValidationDate,
ba.Balance, c.FirstName, c.LastName, c.NationalIdentityNumber 
FROM BankAccounts ba
LEFT JOIN Customers c ON ba.CustomerID = c.CustomerID
LEFT JOIN CardsTwoBankAccounts cba ON ba.BankAccountID = cba.BankAccountID
LEFT JOIN Cards ca ON cba.CardID = ca.CardID

SELECT * From vw_GetCardWithBankAccounts

----------------------------------------------------
CREATE FUNCTION f_AmountConverterToBGN
(
	@Amount money,
	@CurrencyID int
)
RETURNS money
AS
BEGIN
	DECLARE @return_value money;
	SELECT @return_value = @Amount;

	IF (@CurrencyID = 1)
		SELECT @return_value = @Amount * 1.66624;
	IF (@CurrencyID = 2)
		SELECT @return_value = @Amount * 1.95583;
	IF (@CurrencyID = 3)
		SELECT @return_value = @Amount * 1.95583;

	RETURN @return_value;
END

SELECT t.Amount as OriginalAmount, 
dbo.f_AmountConverterToBGN(t.Amount, t.CurrencyID) AS BGNAmount
FROM Transactions t

------------------------------------------------------------------------------
CREATE FUNCTION f_GetBankAccountAttachWithCards
(
	@Balance money
)
RETURNS TABLE
AS
RETURN
(
 SELECT * FROM vw_GetCardWithBankAccounts v 
 WHERE v.CardNumber IS NOT NULL AND
 v.Balance  >= @Balance
)

SELECT * FROM dbo.f_GetBankAccountAttachWithCards(6000)
