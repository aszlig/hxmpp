/*
 *	This file is part of HXMPP.
 *	Copyright (c)2009 http://www.disktree.net
 *	
 *	HXMPP is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  HXMPP is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *	See the GNU Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with HXMPP. If not, see <http://www.gnu.org/licenses/>.
*/
package xmpp.filter;

/**
*/
class PacketPropertyFilter {
	
	public var ns : String;
	public var name : String;
	
	public function new( ns : String, ?name : String ) {
		this.ns = ns;
		this.name = name;
	}
	
	@:keep public function accept( p : xmpp.Packet ) : Bool {
		for( prop in p.properties ) {
			if( ns != null && prop.get( "xmlns" ) != ns )
				continue;
			if( name == null )
				return true;
			if( prop.nodeName == name )
				return true;
		}
		return false;
	}
	
}
