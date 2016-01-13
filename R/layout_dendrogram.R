#' @export
createLayout.dendrogram <- function(graph, layout, circular = FALSE, ...) {
    graph <- identifyNodes(graph)
    if (inherits(layout, 'function')) {
        layout <- layout(graph, circular = circular, ...)
    } else if (inherits(layout, 'character')) {
        layoutName <- paste0('layout_dendrogram_', layout)
        layout <- do.call(layoutName, list(graph, circular = circular, ...))
    } else {
        stop('Unknown layout')
    }
    attr(layout, 'graph') <- graph
    attr(layout, 'circular') <- circular
    class(layout) <- c(
        'layout_dendrogram',
        'layout_ggraph',
        'data.frame'
    )
    checkLayout(layout)
}
#' @export
getEdges.layout_dendrogram <- function(layout) {
    edges <- getConnections(attr(layout, 'graph'))
    extraPar <- bind_rows(lapply(edges$edgePar, as.data.frame, stringsAsFactors = FALSE))
    edges$edgePar <- NULL
    edges <- cbind(edges, extraPar)
    edges$circular <- attr(layout, 'circular')
    checkEdges(addEdgeCoordinates(edges, layout))
}
#' @importFrom dplyr bind_rows
#' @importFrom ggforce radial_trans
layout_dendrogram_dendrogram <- function(graph, circular = FALSE, offset = pi/2, repel = FALSE, ratio = 1) {
    if (repel) {
        heights <- getHeights(graph)
        pad <-  min(heights[heights != 0])/2
    } else {
        pad <- 0
    }
    graph <- setCoord(graph, repel = repel, pad = pad, ratio = ratio)
    layout <- getCoords(graph)
    extraPar <- lapply(layout$nodePar, as.data.frame, stringsAsFactors = FALSE)
    names(extraPar) <- seq_along(extraPar)
    extraPar <- bind_rows(extraPar)
    extraPar$ggraph.dummy <- NULL
    layout$nodePar <- NULL
    layout <- cbind(layout, extraPar)
    layout <- layout[order(layout$ggraph.id), ]
    if (circular) {
        radial <- radial_trans(r.range = rev(range(layout$y)),
                               a.range = range(layout$x),
                               offset = offset,
                               pad = if (repel) (attr(graph, 'height')/2)/ratio else 0.5)
        coords <- radial$transform(layout$y, layout$x)
        layout$x <- coords$x
        layout$y <- coords$y
    }
    layout$circular <- circular
    layout[, !names(layout) %in% c('ggraph.id')]
}
#' @importFrom dplyr bind_rows
#' @importFrom ggforce radial_trans
layout_dendrogram_even <- function(graph, ...) {
    graph <- spreadHeights(graph)
    layout_dendrogram_dendrogram(graph, ...)
}
identifyNodes <- function(den, start = 1) {
    if (is.leaf(den)) {
        attr(den, 'ggraph.id') <- start
    } else {
        den[[1]] <- identifyNodes(den[[1]], start)
        den[[2]] <- identifyNodes(den[[2]], attr(den[[1]], 'ggraph.id') + 1)
        attr(den, 'ggraph.id') <- attr(den[[2]], 'ggraph.id') + 1
    }
    den
}
setCoord <- function(den, offset = 1, repel = TRUE, pad = 0, ratio = 1) {
    if (is.leaf(den)) {
        attr(den, 'ggraph.coord') <- offset
        attr(den, 'rightmost') <- offset
    } else {
        den[[1]] <- setCoord(den[[1]], offset, repel = repel, ratio)
        offset <- attr(den[[1]], 'rightmost')
        offset <- if (repel) {
            offset + (attr(den, 'height') + pad)/ratio
        } else {
            offset + 1 + pad
        }
        den[[2]] <- setCoord(den[[2]], offset, repel = repel, ratio)
        attr(den, 'ggraph.coord') <- mean(unlist(lapply(den, attr, which = 'ggraph.coord')))
        attr(den, 'rightmost') <- attr(den[[2]], 'rightmost')
    }
    den
}
getCoords <- function(den) {
    id <- attr(den, 'ggraph.id')
    label <- attr(den, 'label')
    if (is.null(label)) label <- ''
    members <- attr(den, 'members')
    nodePar <- attr(den, 'nodePar')
    if (is.null(nodePar)) nodePar <- data.frame(ggraph.dummy = 1)
    if (is.leaf(den)) {
        list(
            x = attr(den, 'ggraph.coord'),
            y = attr(den, 'height'),
            ggraph.id = id,
            leaf = TRUE,
            label = label,
            members = members,
            nodePar = list(nodePar)
        )
    } else {
        coord1 <- getCoords(den[[1]])
        coord2 <- getCoords(den[[2]])
        list(
            x = c(coord1$x, coord2$x, attr(den, 'ggraph.coord')),
            y = c(coord1$y, coord2$y, attr(den, 'height')),
            ggraph.id = c(coord1$ggraph.id, coord2$ggraph.id, id),
            leaf = c(coord1$leaf, coord2$leaf, FALSE),
            label = c(coord1$label, coord2$label, label),
            members = c(coord1$members, coord2$members, members),
            nodePar = c(coord1$nodePar, coord2$nodePar, list(nodePar))
        )
    }
}
getConnections <- function(den) {
    id <- attr(den, 'ggraph.id')
    if (is.leaf(den)) {
        data.frame(row.names = 1)
    } else {
        conn1 <- getConnections(den[[1]])
        conn2 <- getConnections(den[[2]])
        list(
            from = c(conn1$from, conn2$from, rep(id, 2)),
            to = c(conn1$to, conn2$to, unlist(lapply(den, attr, which = 'ggraph.id'))),
            label = c(conn1$label, conn2$label, unlist(lapply(den, function(subden) {
                lab <- attr(subden, 'edgetext')
                if (is.null(lab)) '' else lab
            }))),
            direction = c(conn1$direction, conn2$direction, c('right', 'left')),
            edgePar = c(conn1$edgePar, conn2$edgePar, lapply(den, function(subden) {
                par <- attr(subden, 'edgePar')
                if (is.null(par)) data.frame(row.names = 1) else par
            }))
        )
    }
}
spreadHeights <- function(den) {
    if (is.leaf(den)) {
        attr(den, 'height') <- 0
    } else {
        den[[1]] <- spreadHeights(den[[1]])
        den[[2]] <- spreadHeights(den[[2]])
        attr(den, 'height') <- max(sapply(den, attr, 'height')) + 1
    }
    den
}
getHeights <- function(den) {
    if (is.leaf(den)) {
        attr(den, 'height')
    } else {
        c(getHeights(den[[1]]), getHeights(den[[2]]), attr(den, 'height'))
    }
}