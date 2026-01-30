using System.ComponentModel.DataAnnotations;

namespace Chillax.Catalog.API.Model;

public class CatalogType
{
    public CatalogType(string type) {
        Type = type;
    }

    public int Id { get; set; }

    [Required]
    public string Type { get; set; }

    /// <summary>
    /// Arabic name for the category
    /// </summary>
    public string? TypeAr { get; set; }
}
