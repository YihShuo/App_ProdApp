namespace ERP_API.Models
{
    public class MonthOrderResult
    {
        public int Seq { get; set; }

        public string? AssemblyDate { get; set; }

        public string? ShipDate { get; set; }

        public string? Order { get; set; }

        public int Pairs { get; set; }

        public string? SKU { get; set; }

        public string? DieCut { get; set; }

        public string? BuyNo { get; set; }

        public string? Status { get; set; }
    }

    public class DispatchedOrderProgress
    {
        public int Seq { get; set; }

        public string? Order { get; set; }

        public string? BuyNo { get; set; }

        public string? Date { get; set; }

        public string? SKU { get; set; }

        public int Pairs { get; set; }

        public decimal DProgress { get; set; }

        public decimal Progress { get; set; }
    }
}
