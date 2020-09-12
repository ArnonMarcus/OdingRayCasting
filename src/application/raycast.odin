package application

RayHit :: struct {
    is_vertical: bool,
    texture_id: u8,
    distance: f32,
    position: vec2
}
Ray :: struct {
    origin: ^vec2,
    direction: vec2,
    
    rise_over_run,
    run_over_rise: f32,

    is_vertical,
    is_horizontal,
    is_facing_up,
    is_facing_down,
    is_facing_left,
    is_facing_right: bool,

    hit: RayHit
}
horizontal_hit: RayHit;
vertical_hit: RayHit = {is_vertical=true};
all_rays: [MAX_WIDTH]Ray;
rays: []Ray;

rayIntersectsWithEdge :: proc(ray: ^Ray, edge: ^TileEdge, pos: ^vec2) -> bool {
    using edge.local;
    if edge.is_horizontal {
        if ray.is_horizontal || (is_below && ray.is_facing_up) || (is_above && ray.is_facing_down) do return false;
        pos.y = to.y;
        pos.x = to.y * ray.run_over_rise;
        return inRange(pos.x, to.x, from.x);
    } else { // Edge is vertical:
        if ray.is_vertical || (is_left && ray.is_facing_right) || (is_right && ray.is_facing_left) do return false;
        pos.x = to.x;
        pos.y = to.x * ray.rise_over_run;
        return inRange(pos.y, to.y, from.y);
    }
}

HitInfo :: struct {distance_squared: f32, position: vec2};
castRay :: proc(using ray: ^Ray) {
    closest, current: HitInfo;
    closest.distance_squared = 1000000;
    for edge in &tile_map.edges do if edge.is_facing_forward && rayIntersectsWithEdge(ray, &edge, &current.position) {
        current.distance_squared = squared_length(current.position);
        if current.distance_squared < closest.distance_squared do closest = current;
    }
    hit.position = closest.position + origin^;
    hit.distance = sqrt(closest.distance_squared);   
}

generateRays :: proc(using cam: ^Camera2D) {
    using xform;
    ray_direction := forward_direction^ * focal_length;
    ray_direction -= right_direction^;
    ray_direction *= f32(len(rays)) / 2;
    ray_direction += right_direction^ / 2;

    for ray in &rays {
        using ray;
        origin = &position;
        direction = norm(ray_direction);
        rise_over_run = direction.y / direction.x;
        run_over_rise = 1 / rise_over_run;

        is_vertical    = direction.x == 0;
        is_horizontal  = direction.y == 0;
        is_facing_left = direction.x < 0;
        is_facing_up   = direction.y < 0;
        is_facing_right = direction.x > 0;
        is_facing_down  = direction.y > 0;

        ray_direction += right_direction^;
    }
}

setRayCount :: inline proc(count: i32) {
    rays = all_rays[:count];
}

castRays :: inline proc() {
    for ray in &rays do castRay(&ray);
    // for ray in &rays do castRayWolf3D(&ray);
}

// castRayWolf3D :: proc(using ray: ^Ray) {
//     size := f32(tile_map.tile_size);
//     factor :=  1 / size;
    
//     horizontal_hit.position.y = f32(i32(factor * origin.y) * tile_map.tile_size) + (is_facing_down ? size : 0);
//     horizontal_hit.position.x = origin.x + (horizontal_hit.position.y - origin.y) * run_over_rise;
//     inc_y := is_facing_up ? -size : size;
//     inc_x := run_over_rise * ((is_facing_left && rise_over_run > 0) != (is_facing_right && rise_over_run < 0) ? -size : size);
//     findHit(&horizontal_hit, factor, inc_x, inc_y, false, is_facing_up);

//     vertical_hit.position.x = f32(i32(factor * origin.x) * tile_map.tile_size) + (is_facing_right ? size : 0);
//     vertical_hit.position.y = origin.y + (vertical_hit.position.x - origin.x) * rise_over_run;
//     inc_x = is_facing_left ? -size : size;
//     inc_y = rise_over_run * ((is_facing_up && rise_over_run > 0) != (is_facing_down && rise_over_run < 0) ? -size : size);
//     findHit(&vertical_hit, factor, inc_x, inc_y, is_facing_left, false);
    
//     horizontal_hit.distance = squared_length(horizontal_hit.position - origin^);
//       vertical_hit.distance = squared_length(  vertical_hit.position - origin^);
//     hit = horizontal_hit.distance < vertical_hit.distance ? horizontal_hit : vertical_hit;
//     hit.distance = sqrt(hit.distance);
// }
// findHit :: proc(using hit: ^RayHit, factor, inc_x, inc_y: f32, dec_x, dec_y: bool) {
//     tile: ^Tile;
//     x, y: i32;
//     found: bool;
//     end_x := tile_map.width  - 1;
//     end_y := tile_map.height - 1;
//     for !found {
//         x = i32(factor * (dec_x ? (position.x - 1) : position.x));
//         y = i32(factor * (dec_y ? (position.y - 1) : position.y));

//         if inRange(x, end_x) && 
//            inRange(y, end_y) {
//             tile = &tile_map.tiles[y][x];
//             if tile.is_full {
//                 texture_id = tile.texture_id;
//                 found = true;
//             } else {
//                 position.x += inc_x;
//                 position.y += inc_y;
//             }
//         } else do found = true;
//     }
// }
