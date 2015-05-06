// finds the point furthest from a set of points coming in on stdin
//
// Constructs a voronoi diagram, and returns the vertex in the largest cell.
// boost::polygon is used as the voronoi library. I'm not huge fan of it's
// overwrought use of c++, but thankfully, I just hacked up a tutorial, and kept
// the most c++-y sections untouched


#include <stdio.h>
#include <vector>
#include <boost/polygon/voronoi.hpp>


using boost::polygon::voronoi_diagram;

// straight from the tutorial
struct Point
{
    int x,y;
    Point(int _x, int _y) : x(_x), y(_y) {}
};
namespace boost { namespace polygon {
        template <>
        struct geometry_concept<Point> {
            typedef point_concept type;
        };

        template <>
        struct point_traits<Point> {
            typedef int coordinate_type;

            static inline coordinate_type get(
                                              const Point& point, orientation_2d orient) {
                return (orient == HORIZONTAL) ? point.x : point.y;
            }
        };
    }}


int main(void)
{
    std::vector<Point> points;

    int x, y;
    while( 2 == scanf("%d %d", &x, &y) )
        points.push_back(Point(x, y));


    // Construction of the Voronoi Diagram.
    voronoi_diagram<double> vd;
    construct_voronoi(points.begin(), points.end(),
                      &vd);


    for (voronoi_diagram<double>::const_vertex_iterator it = vd.vertices().begin();
         it != vd.vertices().end(); ++it) {

        printf("%g vert %g\n", it->x(), it->y());

        const voronoi_diagram<double>::cell_type* c0 = it->incident_edge()->cell();
        if( c0 != NULL )
        {
            int i = c0->source_index();
            double px = (double)points[i].x;
            double py = (double)points[i].y;

            double dx = px - it->x();
            double dy = py - it->y();
            printf("dist: %g\n", sqrt(dx*dx + dy*dy));
        }
    }
    return 0;
}
