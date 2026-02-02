namespace Chillax.Rooms.Infrastructure.Repositories;

public class RoomRepository : IRoomRepository
{
    private readonly RoomsContext _context;

    public IUnitOfWork UnitOfWork => _context;

    public RoomRepository(RoomsContext context)
    {
        _context = context ?? throw new ArgumentNullException(nameof(context));
    }

    public Room Add(Room room)
    {
        return _context.Rooms.Add(room).Entity;
    }

    public void Update(Room room)
    {
        _context.Entry(room).State = EntityState.Modified;
    }

    public void Delete(Room room)
    {
        _context.Rooms.Remove(room);
    }

    public async Task<Room?> GetAsync(int roomId)
    {
        return await _context.Rooms.FindAsync(roomId);
    }

    public async Task<List<Room>> GetAllAsync()
    {
        return await _context.Rooms
            .OrderBy(r => r.Name.En)
            .ToListAsync();
    }

    public async Task<List<Room>> GetByStatusAsync(RoomPhysicalStatus status)
    {
        return await _context.Rooms
            .Where(r => r.PhysicalStatus == status)
            .OrderBy(r => r.Name.En)
            .ToListAsync();
    }

    public async Task<bool> ExistsAsync(int roomId)
    {
        return await _context.Rooms.AnyAsync(r => r.Id == roomId);
    }
}
