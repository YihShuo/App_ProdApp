namespace ERP_API.Models
{
    public class Stock
    {
        public string? ID { get; set; }

        public string? Type { get; set; }
    }

    public class ListedResponse
    {
        public List<List<string>>? data { get; set; }
    }

    public class OTCResponse
    {
        public List<OTCTables>? tables { get; set; }
    }

    public class OTCTables
    {
        public List<List<string>>? data { get; set; }
    }
}
