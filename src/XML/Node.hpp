/**
 ****************************************************************************
 * <P> XML.c - implementation file for basic XML parser written in ANSI C++
 * for portability. It works by using recursion and a node tree for breaking
 * down the elements of an XML document.  </P>
 *
 * @version     V1.08
 *
 * @author      Frank Vanden Berghen
 * based on original implementation by Martyn C Brown
 *
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License version 2.1 as published by the Free Software Foundation
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 ****************************************************************************
 */

#ifndef XCSOAR_XML_NODE_HPP
#define XCSOAR_XML_NODE_HPP

#include "Util/NonCopyable.hpp"
#include "Util/tstring.hpp"
#include "Compiler.h"

#include <list>
#include <forward_list>

#include <assert.h>
#include <tchar.h>
#include <stdlib.h>

class TextWriter;

struct XMLNode {
//  friend class XMLNode;
protected:
  /**
   * To allow shallow copy and "intelligent/smart" pointers (automatic
   * delete).
   */
  struct Data : private NonCopyable {
    /** Structure for XML attribute. */
    struct Attribute : private NonCopyable {
      TCHAR *name;
      TCHAR *value;

      Attribute(TCHAR *_name, TCHAR *_value)
        :name(_name), value(_value) {}

      ~Attribute() {
        free(name);
        free(value);
      }
    };

    /** Element name (=NULL if root) */
    const TCHAR *name;

    /** Whether node is an XML declaration - '<?xml ?>' */
    bool is_declaration;

    /** Array of child nodes */
    std::list<XMLNode> children;

    /** A concatentation of all text nodes */
    tstring text;

    /** Array of attributes */
    std::forward_list<Attribute> attributes;

    unsigned ref_count;

    Data(const TCHAR *_name, bool _is_declaration)
      :name(_name),
       is_declaration(_is_declaration),
       ref_count(1) {}
    ~Data();

    void Ref();
    void Unref();

    bool HasChildren() const {
      return !children.empty() || !text.empty();
    }

    void AddAttribute(TCHAR *name, TCHAR *value) {
      attributes.emplace_front(name, value);
    }

    typedef std::list<XMLNode>::const_iterator const_iterator;

    const_iterator begin() const {
      return children.begin();
    }

    const_iterator end() const {
      return children.end();
    }
  };

  Data *d;

  /**
   * Protected constructor: use "parse" functions to get your first
   * instance of XMLNode.
   */
  XMLNode(const TCHAR *name, bool is_declaration);

public:
  static inline XMLNode Null() {
    return XMLNode(NULL, false);
  }

  static XMLNode CreateRoot(const TCHAR *name);

  /**
   * name of the node
   */
  const TCHAR *GetName() const {
    assert(d != NULL);

    return d->name;
  }

  typedef Data::const_iterator const_iterator;

  const_iterator begin() const {
    return d->begin();
  }

  const_iterator end() const {
    return d->end();
  }

  /**
   * @return the first child node, or NULL if there is none
   */
  gcc_pure
  const XMLNode *GetFirstChild() const {
    return d != NULL && !d->children.empty()
      ? &d->children.front()
      : NULL;
  }

  /**
   * @return the first child node, or NULL if there is none
   */
  gcc_pure
  XMLNode *GetFirstChild() {
    return d != NULL && !d->children.empty()
      ? &d->children.front()
      : NULL;
  }

public:
  /**
   * @return ith child node with specific name (return an empty node
   * if failing)
   */
  gcc_pure
  const XMLNode *GetChildNode(const TCHAR *name) const;

  /**
   * @return ith attribute content with specific name (return a NULL
   * if failing)
   */
  gcc_pure
  const TCHAR *GetAttribute(const TCHAR *name) const;

  /**
   * Create an XML file from the head element.
   *
   * @param writer the stream to write the XML text to

   * @param format 0 if no formatting is required, otherwise nonzero
   * for formatted text with carriage returns and indentation.
   */
  void Serialise(TextWriter &writer, int format) const;

  gcc_pure
  bool IsDeclaration() const {
    assert(d != NULL);

    return d->is_declaration;
  }

  // to allow shallow copy:
  ~XMLNode() {
    if (d != NULL)
      d->Unref();
  }

  /**
   * Shallow copy.
   */
  XMLNode(const XMLNode &A);

  XMLNode(XMLNode &&other)
    :d(other.d) {
    other.d = NULL;
  }

  /**
   * Shallow copy.
   */
  XMLNode &operator=(const XMLNode& A);

  XMLNode &operator=(XMLNode &&other) {
    Data *old = d;
    d = other.d;
    other.d = NULL;

    if (old != NULL)
      old->Unref();

    return *this;
  }

  gcc_constexpr_ctor
  XMLNode(): d(NULL) {}

  // The strings given as parameters for these 4 methods will be free'd by the XMLNode class:

  /**
   * Add a child node to the given element.
   */
  XMLNode &AddChild(const TCHAR *name, bool is_declaration);

  /**
   * Add an attribute to an element.
   */
  void AddAttribute(TCHAR *name, TCHAR *value);

  /**
   * Add text to the element.
   */
  void AddText(const TCHAR *value);

  void AddText(const TCHAR *text, size_t length);

private:
  /**
   * Creates an user friendly XML string from a given element with
   * appropriate white space and carriage returns.
   *
   * This recurses through all subnodes then adds contents of the
   * nodes to the string.
   */
  static void Serialise(const Data &data, TextWriter &writer, int format);
};

#endif
