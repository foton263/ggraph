#' Draw edges as straight lines between nodes
#'
#' This geom draws edges in the simplest way - as straight lines between the
#' start and end nodes. Not much more to say about that...
#'
#' @details
#' Many geom_edge_* layers comes in 3 flavors depending on the level of control
#' needed over the drawing. The default (no numeric postfix) generate a number
#' of points (\code{n}) along the edge and draws it as a path. Each point along
#' the line has a numeric value associated with it giving the position along the
#' path, and it is therefore possible to show the direction of the edge by
#' mapping to this e.g. \code{colour = ..index..}. The version postfixed with a
#' "2" uses the "long" edge format (see \code{\link{gEdges}}) and makes it
#' possible to interpolate node parameter between the start and end node along
#' the edge. It is considerable less performant so should only be used if this
#' is needed. The version postfixed with a "0" draws the edge in the most
#' performant way, often directly using an appropriate grob from the grid
#' package, but does not allow for gradients along the edge.
#'
#' @note In order to avoid excessive typing edge aesthetic names are
#' automatically expanded. Because of this it is not necessary to write
#' \code{edge_colour} within the \code{aes()} call as \code{colour} will
#' automatically be renamed appropriately.
#'
#' @section Aesthetics:
#' geom_edge_link and geom_edge_link0 understand the following
#' aesthetics. Bold aesthetics are automatically set, but can be overridden.
#' \itemize{
#'  \item{\strong{x}}
#'  \item{\strong{y}}
#'  \item{\strong{xend}}
#'  \item{\strong{yend}}
#'  \item{edge_colour}
#'  \item{edge_width}
#'  \item{edge_linetype}
#'  \item{edge_alpha}
#'  \item{filter}
#' }
#' geom_edge_link2 understand the following aesthetics. Bold aesthetics are
#' automatically set, but can be overridden.
#' \itemize{
#'  \item{\strong{x}}
#'  \item{\strong{y}}
#'  \item{\strong{group}}
#'  \item{edge_colour}
#'  \item{edge_width}
#'  \item{edge_linetype}
#'  \item{edge_alpha}
#'  \item{filter}
#' }
#'
#' @section Computed variables:
#'
#' \describe{
#'  \item{index}{The position along the path (not computed for the *0 version)}
#' }
#'
#' @inheritParams ggplot2::geom_path
#'
#' @param mapping Set of aesthetic mappings created by \code{\link[ggplot2]{aes}}
#' or \code{\link[ggplot2]{aes_}}. By default x, y, xend, yend, group and
#' circular are mapped to x, y, xend, yend, edge.id and circular in the edge
#' data.
#'
#' @param data The return of a call to \code{gEdges()} or a data.frame
#' giving edges in corrent format (see details for for guidance on the format).
#' See \code{\link{gEdges}} for more details on edge extraction.
#'
#' @param n The number of points to create along the path.
#'
#' @author Thomas Lin Pedersen
#'
#' @family geom_edge_*
#'
#' @examples
#' require(igraph)
#' gr <- make_graph('bull')
#' E(gr)$class <- sample(letters[1:3], gsize(gr), replace = TRUE)
#' V(gr)$class <- sample(letters[1:3], gorder(gr), replace = TRUE)
#'
#' ggraph(gr, 'igraph', algorithm = 'nicely') +
#'   geom_edge_link(aes(alpha = ..index..))
#'
#' ggraph(gr, 'igraph', algorithm = 'nicely') +
#'   geom_edge_link2(aes(colour = node.class),
#'                  gEdges('long', nodePar = 'class'))
#'
#' ggraph(gr, 'igraph', algorithm = 'nicely') +
#'   geom_edge_link0(aes(colour = class))
#'
#' @rdname geom_edge_link
#' @name geom_edge_link
#'
NULL

#' @rdname ggraph-extensions
#' @format NULL
#' @usage NULL
#' @importFrom ggforce StatLink
#' @export
StatEdgeLink <- ggproto('StatEdgeLink', StatLink,
    setup_data = function(data, params) {
        if (any(names(data) == 'filter')) {
            if (!is.logical(data$filter)) {
                stop('filter must be logical')
            }
            data <- data[data$filter, names(data) != 'filter']
        }
        StatLink$setup_data(data, params)
    },
    default_aes = aes(filter = TRUE)
)
#' @rdname ggraph-extensions
#' @format NULL
#' @usage NULL
#' @importFrom ggforce StatLink2
#' @export
StatEdgeLink2 <- ggproto('StatEdgeLink2', StatLink2,
    setup_data = function(data, params) {
        if (any(names(data) == 'filter')) {
            if (!is.logical(data$filter)) {
                stop('filter must be logical')
            }
            data <- data[data$filter, names(data) != 'filter']
        }
        StatLink2$setup_data(data, params)
    },
    default_aes = aes(filter = TRUE)
)
#' @rdname geom_edge_link
#'
#' @importFrom ggforce StatLink
#' @export
geom_edge_link <- function(mapping = NULL, data = gEdges('short'),
                           position = "identity", arrow = NULL,
                           lineend = "butt", show.legend = NA, n=100, ...) {
    mapping <- completeEdgeAes(mapping)
    mapping <- aesIntersect(mapping, aes_(x=~x, y=~y, xend=~xend, yend=~yend))
    layer(data = data, mapping = mapping, stat = StatEdgeLink,
          geom = GeomEdgePath, position = position, show.legend = show.legend,
          inherit.aes = FALSE,
          params = expand_edge_aes(
              list(arrow = arrow, lineend = lineend, na.rm = FALSE, n = n,
                        interpolate = FALSE, ...)
          )
    )
}
#' @rdname geom_edge_link
#'
#' @importFrom ggforce StatLink2
#' @export
geom_edge_link2 <- function(mapping = NULL, data = gEdges('long'),
                           position = "identity", arrow = NULL,
                           lineend = "butt", show.legend = NA, n=100, ...) {
    mapping <- completeEdgeAes(mapping)
    mapping <- aesIntersect(mapping, aes_(x=~x, y=~y, group=~edge.id))
    layer(data = data, mapping = mapping, stat = StatEdgeLink2,
          geom = GeomEdgePath, position = position, show.legend = show.legend,
          inherit.aes = FALSE,
          params = expand_edge_aes(
              list(arrow = arrow, lineend = lineend, na.rm = FALSE, n = n,
                        interpolate = TRUE, ...)
          )
    )
}
#' @rdname geom_edge_link
#'
#' @importFrom ggforce StatLink2
#' @export
geom_edge_link0 <- function(mapping = NULL, data = gEdges(),
                            position = "identity", arrow = NULL,
                            lineend = "butt", show.legend = NA, ...) {
    mapping <- completeEdgeAes(mapping)
    mapping <- aesIntersect(mapping, aes_(x=~x, y=~y, xend=~xend, yend=~yend))
    layer(data = data, mapping = mapping, stat = StatFilter,
          geom = GeomEdgeSegment, position = position,
          show.legend = show.legend, inherit.aes = FALSE,
          params = expand_edge_aes(
              list(arrow = arrow, lineend = lineend, na.rm = FALSE, ...)
          )
    )
}
