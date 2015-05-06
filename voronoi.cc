// finds the point furthest from a set of points read in from a file given on
// stdin
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
    // first I read off my data bounds, then the rest follows
    int xmin, ymin;
    int xmax, ymax;
    scanf("%d %d %d %d", &xmin, &ymin, &xmax, &ymax);

    std::vector<Point> points;
    int x, y;
    while( 2 == scanf("%d %d", &x, &y) )
        points.push_back(Point(x, y));


    // Construction of the Voronoi Diagram.
    voronoi_diagram<double> vd;
    construct_voronoi(points.begin(), points.end(),
                      &vd);


    double distsq_furthest = -1.0;
    int x_furthest = 0, y_furthest = 0;


    for (voronoi_diagram<double>::const_vertex_iterator it = vd.vertices().begin();
         it != vd.vertices().end(); ++it) {

        if( (int)it->x() <= xmin || (int)it->x() >= xmax ||
            (int)it->y() <= ymin || (int)it->y() >= ymax )
            continue;

        double distsq = -1.0;

        const voronoi_diagram<double>::cell_type* c0 = it->incident_edge()->cell();
        if( c0 != NULL )
        {
            int i = c0->source_index();
            double px = (double)points[i].x;
            double py = (double)points[i].y;

            double dx = px - it->x();
            double dy = py - it->y();
            distsq = dx*dx + dy*dy;
        }

        if( distsq > distsq_furthest)
        {
            distsq_furthest = distsq;
            x_furthest = (int)round(it->x());
            y_furthest = (int)round(it->y());
        }
    }

    printf("furthest: (%d,%d) dist: %g\n", x_furthest, y_furthest, sqrt(distsq_furthest));
    return 0;
}
