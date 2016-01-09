// Copyright 2015, Christopher J. Foster and the other displaz contributors.
// Use of this code is governed by the BSD-style license found in LICENSE.txt

#ifndef DISPLAZ_GEOMETRYCOLLECTION_H_INCLUDED
#define DISPLAZ_GEOMETRYCOLLECTION_H_INCLUDED

#include <vector>

#include <QAbstractListModel>
#include <QItemSelectionModel>

#include "geometry.h"
#include "fileloader.h"


/// Collection of loaded data sets for use with Qt's model view architecture
///
/// Data sets can be points, lines or meshes.
class GeometryCollection : public QAbstractListModel
{
    Q_OBJECT
    public:
        typedef std::vector<std::shared_ptr<Geometry>> GeometryVec;

        GeometryCollection(QObject * parent = 0);

        /// Get current list of geometries
        const GeometryVec& get() const { return m_geometries; }

        /// Remove all geometries from the list
        void clear();

        /// Remove identified geometry from list
        ///
        /// Return true if the geometry was found, false otherwise.
        bool erase(GeometryId id);

        // Following implemented from QAbstractListModel:
        virtual int rowCount(const QModelIndex & parent = QModelIndex()) const;
        virtual QVariant data(const QModelIndex & index, int role = Qt::DisplayRole) const;
        virtual Qt::ItemFlags flags(const QModelIndex& index) const;
        virtual bool setData(const QModelIndex & index, const QVariant & value,
                             int role = Qt::EditRole);

        virtual bool removeRows(int row, int count, const QModelIndex& parent = QModelIndex());


    public slots:
        /// Add to the list of loaded geometries
        ///
        /// If `reloaded` is true, search existing geometry for
        /// `geom->fileName()` and if found, replace the existing geometry.
        void addGeometry(std::shared_ptr<Geometry> geom, bool reloaded = false);

    private:
        void loadPointFilesImpl(const QStringList& fileNames, bool removeAfterLoad);

        GeometryVec m_geometries;
};


#endif // DISPLAZ_GEOMETRYCOLLECTION_H_INCLUDED
