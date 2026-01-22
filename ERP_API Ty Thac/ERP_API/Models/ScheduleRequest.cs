namespace ERP_API.Models
{
    public class ScheduleRequest
    {
        public string? Month { get; set; }

        public string? Date { get; set; }

        public string? Area { get; set; }

        public string? Building { get; set; }

        public string? Lean { get; set; }

        public string? Section { get; set; }

        public string? Type { get; set; }

        public string? ListNo { get; set; }
    }

    public class ProductionScheduleRequest
    {
        public string? StartDate { get; set; }

        public string? EndDate { get; set; }

        public string? Area { get; set; }

        public string? Building { get; set; }

        public string? Mode { get; set; }

        public string? Version { get; set; }

        public string? OrderDate { get; set; }
    }
}
